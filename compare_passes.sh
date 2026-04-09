#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
BUILD="$REPO/build"
IR_DIR="$REPO/benchmarks/ir"
OPT=opt-20

PLUGIN_MAIN="$BUILD/libFencePass.so"
PLUGIN_NAIVE="$BUILD/libFencePassBaselineNaive.so"
# check if files exist in actuality
if [[ ! -f "$PLUGIN_MAIN" || ! -f "$PLUGIN_NAIVE" ]]; then
  echo "Building plugins..."
  cmake -S "$REPO" -B "$BUILD" \
    -DLLVM_INSTALL_DIR=/usr/lib/llvm-20 \
    -DCMAKE_CXX_COMPILER=/usr/lib/llvm-20/bin/clang++ \
    -DCMAKE_CXX_FLAGS="" >/dev/null
  make -C "$BUILD" -j"$(nproc)" >/dev/null
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
