#include <map>
#include <unordered_set>

#include "llvm/Passes/PassBuilder.h"
#include "llvm/Plugins/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"

#include <llvm/IR/IRBuilder.h>
#include <llvm/Analysis/AliasAnalysis.h>
#include <llvm/Analysis/AliasAnalysisEvaluator.h>

using namespace llvm;

namespace fencepass {
    void insertFenceBefore(Instruction &I) {
        IRBuilder Builder(I.getContext());
        Builder.SetInsertPoint(&I);
        Builder.CreateFence(AtomicOrdering::SequentiallyConsistent);
    }

    bool isSeqFence(const Instruction &I) {
        if (I.getOpcode() != Instruction::Fence) return false;
        if (const auto *FI = dyn_cast<FenceInst>(&I)) {
            const auto &order = FI->getOrdering();
            return order == AtomicOrdering::SequentiallyConsistent;
        }
        return false;
    }

    bool isMemoryAccess(const Instruction &I) {
        return I.getOpcode() == Instruction::Store ||
               I.getOpcode() == Instruction::AtomicRMW ||
               I.getOpcode() == Instruction::Load;
    }

    enum MemAccessKind {
        Load,
        Store,
        AtomicRMW,
    };

    class MemAccess {
    public:
        MemAccessKind kind;
        Value *ptr;
    };

    bool operator<(const MemAccess &lhs, const MemAccess &rhs) {
        if (lhs.kind != rhs.kind) {
            return lhs.kind < rhs.kind;
        }

        return lhs.ptr < rhs.ptr;
    }

    MemAccess memAccessFromInstruction(const Instruction &I) {
        if (I.getOpcode() == Instruction::Store)
            return {Store, I.getOperand(1)};
        if (I.getOpcode() == Instruction::AtomicRMW)
            return {AtomicRMW, I.getOperand(1)};
        if (I.getOpcode() == Instruction::Load)
            return {Load, I.getOperand(0)};
        errs() << "Unsupported memory access instruction: " << I.getOpcodeName();
        return {Load, nullptr};
    }

    struct CFPath {
        // blocks visited, except for the block containing the instruction we started from
        std::set<BasicBlock *> visited_basic_blocks;
        std::vector<Instruction *> path;
    };

    struct Map {
        std::map<Instruction *, int> map;

        void increment(Instruction *I) {
            if (map.find(I) == map.end()) {
                map[I] = 1;
            } else {
                map[I]++;
            }
        }

        void commitPath(const CFPath &path) {
            for (const auto &I: path.path) {
                increment(I);
            }
        }
    };

    void printMap(const Map &map) {
        auto &e = errs();

        e << "Map: \n";
        for (const auto &[fst, snd]: map.map) {
            e << "Before instruction : " << *fst << ", Count: " << snd << "\n";
        }
    }

    Instruction *fencePoint(const Map &map) {
        Instruction *ptr = nullptr;
        int mx = -1;
        for (const auto &[fst, snd]: map.map) {
            if (snd > mx) {
                mx = snd;
                ptr = fst;
            }
        }

        return ptr;
    }

    bool doCommitByAAResult(AliasResult result) {
        bool doCommit = false;
        switch (result) {
            case AliasResult::NoAlias:
            case AliasResult::MayAlias:
            case AliasResult::PartialAlias:
                doCommit = true;
                break;
            case AliasResult::MustAlias:
                doCommit = false;
                break;
            default:
                break;
        }
        return doCommit;
    }

    void floodPaths(
        AAResults &alias_analysis_results,
        Value *initial_value,
        Map &map,
        CFPath &currentPath,
        BasicBlock *bb,
        BasicBlock::iterator bbIter,
        const bool fenceWithStore) {
        if (bbIter == bb->end()) {
            for (const auto succ: successors(bb)) {
                if (currentPath.visited_basic_blocks.find(succ) != currentPath.visited_basic_blocks.end()) {
                    // if we didnt find any conflicts the first time going through this block, we sure won't find any
                    // conflicts going through it a second time.
                    continue;
                }
                currentPath.visited_basic_blocks.insert(succ);
                CFPath cpClone = currentPath;
                floodPaths(alias_analysis_results, initial_value, map, cpClone, succ, succ->begin(),
                           fenceWithStore);
                currentPath.visited_basic_blocks.erase(succ);
            }
            return;
        }

        auto &I = *bbIter;

        if (isSeqFence(I)) {
            return;
        }

        if (I.getOpcode() != Instruction::PHI) {
            currentPath.path.emplace_back(&I);
        }

        if (isMemoryAccess(I)) {
            auto [kind, newValue] = memAccessFromInstruction(I);

            switch (kind) {
                case Load:
                case AtomicRMW:
                    if (doCommitByAAResult(alias_analysis_results.alias(initial_value, newValue)))
                        map.commitPath(currentPath);
                    break;
                case Store:
                    if (fenceWithStore) {
                        if (doCommitByAAResult(alias_analysis_results.alias(initial_value, newValue)))
                            map.commitPath(currentPath);
                    }
                    break;
            }

            return;
        }

        ++bbIter;
        floodPaths(
            alias_analysis_results,
            initial_value,
            map,
            currentPath,
            bb,
            bbIter,
            fenceWithStore);
    }

    Map runCFAnalysis(
        Function &F,
        const bool allowStoreStoreReordering,
        AAResults &alias_analysis_results) {
        Map map;
        for (auto &BB: F) {
            for (auto it = BB.begin(); it != BB.end(); ++it) {
                Instruction &I = *it;
                if (!isMemoryAccess(I)) continue;

                auto [kind, ptr] = memAccessFromInstruction(I);

                if (kind == AtomicRMW) continue;

                bool fenceWithStore = true;
                if (kind == Store && allowStoreStoreReordering) {
                    fenceWithStore = false;
                }

                auto current = CFPath{{}, {}};

                auto passedIt = it;
                ++passedIt;

                floodPaths(
                    alias_analysis_results,
                    ptr,
                    map,
                    current,
                    &BB,
                    passedIt,
                    fenceWithStore);
            }
        }
        return map;
    }

    // This method implements what the pass does
    bool visitor(Function &F, FunctionAnalysisManager &FAM, bool allowStoreStoreReordering) {
        AAResults &results = FAM.getResult<AAManager>(F);

        bool changed = false;

        while (true) {
            Map bbfences = runCFAnalysis(F, allowStoreStoreReordering, results);

            const auto fp = fencePoint(bbfences);

            if (fp == nullptr) {
                break;
            }

            insertFenceBefore(*fp);
            changed = true;
        }
        return changed;
    }

    // New PM implementation
    struct FencePass : PassInfoMixin<FencePass> {
        bool allowStoreStoreReordering;

        FencePass(bool allowStoreStoreReordering) : allowStoreStoreReordering(allowStoreStoreReordering) {
        }

        // Main entry point, takes IR unit to run the pass on (&F) and the
        // corresponding pass manager (to be queried if need be)
        PreservedAnalyses run(Function &F, FunctionAnalysisManager &FAM) {
            const bool changed = visitor(F, FAM, allowStoreStoreReordering);
            return changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
        }

        // Without isRequired returning true, this pass will be skipped for functions
        // decorated with the optnone LLVM attribute. Note that clang -O0 decorates
        // all functions with optnone.
        static bool isRequired() { return true; }
    };
} // namespace fencepass

//-----------------------------------------------------------------------------
// New PM Registration
//-----------------------------------------------------------------------------
llvm::PassPluginLibraryInfo getFencePassPluginInfo() {
    return {
        LLVM_PLUGIN_API_VERSION, "FencePass", LLVM_VERSION_STRING,
        [](PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](StringRef Name, FunctionPassManager &FPM,
                   ArrayRef<PassBuilder::PipelineElement>) {
                    if (Name == "FencePassTSO") {
                        FPM.addPass(AAEvaluator());
                        FPM.addPass(fencepass::FencePass(false));
                        return true;
                    }

                    if (Name == "FencePassPSO") {
                        FPM.addPass(AAEvaluator());
                        FPM.addPass(fencepass::FencePass(true));
                        return true;
                    }

                    return false;
                });
        }
    };
}

// This is the core interface for pass plugins. It guarantees that 'opt' will
// be able to recognize HelloWorld when added to the pass pipeline on the
// command line, i.e. via '-passes=hello-world'
extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
    return getFencePassPluginInfo();
}
