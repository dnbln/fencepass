#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
BUILD="$REPO/build"
IR_DIR="$REPO/benchmarks/ir"
OPT=opt-20

PLUGIN_MAIN="$BUILD/libFencePass.so"
PLUGIN_NAIVE="$BUILD/libFencePassBaselineNaive.so"

# Build if either plugin is missing
if [[ ! -f "$PLUGIN_MAIN" || ! -f "$PLUGIN_NAIVE" ]]; then
  echo "Building plugins..."
  cmake -S "$REPO" -B "$BUILD" \
    -DLLVM_INSTALL_DIR=/usr/lib/llvm-20 \
    -DCMAKE_CXX_COMPILER=/usr/lib/llvm-20/bin/clang++ \
    -DCMAKE_CXX_FLAGS="" >/dev/null
  make -C "$BUILD" -j"$(nproc)" >/dev/null
fi

count_fences() {
  local plugin="$1" ir="$2"
  "$OPT" -load-pass-plugin "$plugin" -passes=FencePass "$ir" -S -o - 2>/dev/null \
    | grep -c 'fence syncscope.*seq_cst\|^  fence seq_cst' || true
}

printf "%-20s %10s %10s\n" "Benchmark" "FencePass" "Naive"
printf "%-20s %10s %10s\n" "---------" "---------" "-----"

for ir in "$IR_DIR"/*.ll; do
  name="$(basename "$ir" .ll)"
  main_count="$(count_fences "$PLUGIN_MAIN"  "$ir")"
  naive_count="$(count_fences "$PLUGIN_NAIVE" "$ir")"
  printf "%-20s %10s %10s\n" "$name" "$main_count" "$naive_count"
done
