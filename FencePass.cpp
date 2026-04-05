#include "llvm/Passes/PassBuilder.h"
#include "llvm/Plugins/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"

#include <llvm/IR/IRBuilder.h>

using namespace llvm;

namespace {
    void insertFenceBefore(Instruction &I) {
        IRBuilder Builder(I.getContext());
        Builder.SetInsertPoint(&I);
        Builder.CreateFence(AtomicOrdering::SequentiallyConsistent);
    }

    void insertFenceAfter(Instruction &I) {
        IRBuilder Builder(I.getContext());
        Builder.SetInsertPoint(I.getNextNode());
        Builder.CreateFence(AtomicOrdering::SequentiallyConsistent);
    }

    void fenceAround(Instruction &I) {
        insertFenceBefore(I);
        insertFenceAfter(I);
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

    // This method implements what the pass does
    bool visitor(Function &F) {
        bool changed = false;
        for (auto &BB: F) {
            for (auto &I: BB) {
                if (isMemoryAccess(I)) {
                    fenceAround(I);
                    changed = true;
                }
            }
        }

        for (auto &BB: F) {
            for (auto &I: BB) {
                Instruction *next = I.getNextNode();
                if (next == nullptr) continue;
                if (isSeqFence(I) && isSeqFence(*next)) {
                    next->eraseFromParent();
                    changed = true;
                }
            }
        }


        bool fixpoint = false;
        while (!fixpoint) {
            fixpoint = true;
            for (auto &BB: F) {
                for (auto I = BB.begin(); I != BB.end(); ++I) {
                    if (!isSeqFence(*I)) { continue; }
                    auto next = I;
                    ++next;
                    bool anyMemoryAccess = false;
                    while (next != BB.end()) {
                        if (isSeqFence(*next)) break;
                        if (isMemoryAccess(*next)) anyMemoryAccess = true;
                        ++next;
                    }

                    if (next == BB.end() || anyMemoryAccess) continue;

                    next->removeFromParent();

                    fixpoint = false;
                    changed = true;
                }
            }
        }

        fixpoint = false;
        while (!fixpoint) {
            fixpoint = true;
            for (auto &BB: F) {
                BasicBlock::iterator loopNext;
                for (auto I = BB.begin(); I != BB.end(); I = loopNext) {
                    loopNext = I;
                    ++loopNext;
                    if (!isSeqFence(*I)) continue;
                    auto next = I;
                    if (next == BB.begin()) continue;
                    do {
                        --next;
                    } while (next != BB.begin() && !isMemoryAccess(*next));
                    auto afterNext = next;
                    ++afterNext;
                    if (afterNext == I) continue;
                    if (isMemoryAccess(*next)) {
                        I->removeFromParent();
                        insertFenceAfter(*next);
                        changed = true;
                        fixpoint = false;
                    } else if (next == BB.begin()) {
                        I->removeFromParent();
                        insertFenceBefore(*next);
                        changed = true;
                        fixpoint = false;
                    }
                }
            }
        }
        return changed;
    }

    // New PM implementation
    struct FencePass : PassInfoMixin<FencePass> {
        // Main entry point, takes IR unit to run the pass on (&F) and the
        // corresponding pass manager (to be queried if need be)
        PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
            const bool changed = visitor(F);
            return changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
        }

        // Without isRequired returning true, this pass will be skipped for functions
        // decorated with the optnone LLVM attribute. Note that clang -O0 decorates
        // all functions with optnone.
        static bool isRequired() { return true; }
    };
} // namespace

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
                    if (Name == "FencePass") {
                        FPM.addPass(FencePass());
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
