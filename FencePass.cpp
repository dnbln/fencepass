#include "llvm/Passes/PassBuilder.h"
#include "llvm/Plugins/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"

#include <llvm/IR/IRBuilder.h>

using namespace llvm;

namespace {

void fenceAround(Instruction &I) {
  IRBuilder Builder(I.getContext());
  Builder.SetInsertPoint(&I);
  Builder.CreateFence(AtomicOrdering::SequentiallyConsistent);
  Builder.SetInsertPoint(I.getNextNode());
  Builder.CreateFence(AtomicOrdering::SequentiallyConsistent);
}

// This method implements what the pass does
bool visitor(Function &F) {
  bool changed = false;
  for (auto &BB : F) {
    for (auto &I : BB) {
      if (I.getOpcode() == Instruction::Store ||
          I.getOpcode() == Instruction::AtomicRMW ||
          I.getOpcode() == Instruction::Load) {
        fenceAround(I);
        changed = true;
      }
    }
  }

  // for (auto &BB : F) {
  //   for (auto &I : BB) {
  //     if (I.getOpcode() == Instruction::Fence) {
  //       if (const auto *FI = dyn_cast<FenceInst>(&I)) {
  //         const auto& order = FI->getOrdering();
  //         if (order == AtomicOrdering::SequentiallyConsistent) {
  //           errs() << "fence, ordering: SeqCst\n";
  //         }
  //       }
  //     }
  //   }
  // }

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
  return {LLVM_PLUGIN_API_VERSION, "FencePass", LLVM_VERSION_STRING,
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
          }};
}

// This is the core interface for pass plugins. It guarantees that 'opt' will
// be able to recognize HelloWorld when added to the pass pipeline on the
// command line, i.e. via '-passes=hello-world'
extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return getFencePassPluginInfo();
}
