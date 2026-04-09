#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
BUILD="$REPO/build"
IR_DIR="$REPO/benchmarks/ir"
LLVM_INSTALL_DIR="$REPO/../llvm-project-22.1.2.src/installation/"
OPT=$LLVM_INSTALL_DIR/bin/opt

PLUGIN_MAIN="$BUILD/libFencePass.dylib"
PLUGIN_NAIVE="$BUILD/libFencePassBaselineNaive.dylib"
# check if files exist in actuality
if [[ ! -f "$PLUGIN_MAIN" || ! -f "$PLUGIN_NAIVE" ]]; then
  echo "Building plugins..."
  cmake -S "$REPO" -B "$BUILD" \
    -DLLVM_INSTALL_DIR=$LLVM_INSTALL_DIR \
    -DCMAKE_CXX_COMPILER=$LLVM_INSTALL_DIR/bin/clang++ \
    -DCMAKE_CXX_FLAGS="" -G Ninja >/dev/null
  cmake --build "$BUILD" >/dev/null
fi

count_fences() {
  local plugin="$1" ir="$2" pass="$3"
  "$OPT" -load-pass-plugin "$plugin" -passes=$pass "$ir" -S -o - 2>/dev/null |
    grep -c 'fence syncscope.*seq_cst\|^  fence seq_cst' || true
}

printf "%-20s %15s %15s %15s\n" "Benchmark" "FencePassTSO" "FencePassPSO" "Naive"
printf "%-20s %15s %15s %15s\n" "---------" "------------" "------------" "-----"

for ir in "$IR_DIR"/*.ll; do
  name="$(basename "$ir" .ll)"
  main_count_tso="$(count_fences "$PLUGIN_MAIN" "$ir" "FencePassTSO")"
  main_count_pso="$(count_fences "$PLUGIN_MAIN" "$ir" "FencePassPSO")"
  naive_count="$(count_fences "$PLUGIN_NAIVE" "$ir" "FencePass")"
  printf "%-20s %15s %15s %15s\n" "$name" "$main_count_tso" "$main_count_pso" "$naive_count"
done
