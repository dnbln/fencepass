#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
BUILD="$REPO/build"
IR_DIR="$REPO/benchmarks/ir"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

OPT=opt-20
CLANG=clang-20
RUNS=${RUNS:-10}

PLUGIN_MAIN="$BUILD/libFencePass.so"
PLUGIN_NAIVE="$BUILD/libFencePassBaselineNaive.so"

if [[ ! -f "$PLUGIN_MAIN" || ! -f "$PLUGIN_NAIVE" ]]; then
  echo "Building plugins..."
  cmake -S "$REPO" -B "$BUILD" \
    -DLLVM_INSTALL_DIR=/usr/lib/llvm-20 \
    -DCMAKE_CXX_COMPILER=/usr/lib/llvm-20/bin/clang++ \
    -DCMAKE_CXX_FLAGS="" >/dev/null
  make -C "$BUILD" -j"$(nproc)" >/dev/null
fi

compile_ir() {
  local out="$1" ir="$2"
  "$CLANG" -x ir "$ir" -O0 -o "$out" 2>/dev/null
}

# $1 = output binary, $2 = plugin .so, $3 = pass name (FencePassTSO|FencePassPSO), $4 = input IR
compile_with_pass() {
  local out="$1" plugin="$2" pass="$3" ir="$4"
  local patched="$TMP/$(basename "$ir" .ll)_${pass}_$(basename "$plugin" .so).ll"
  "$OPT" -load-pass-plugin "$plugin" -passes="$pass" "$ir" -S -o "$patched" 2>/dev/null
  compile_ir "$out" "$patched"
}

measure_cpu_ms() {
  local bin="$1"
  local perf_out
  perf_out=$(perf stat -r "$RUNS" "$bin" 2>&1 >/dev/null)
  local line val
  line=$(echo "$perf_out" | grep 'task-clock' || true)
  val="${line%%task-clock*}"
  val="${val//,/}"
  val="${val// /}"
  printf "%.3f" "$(echo "scale=6; $val / 1000000" | bc)"
}

printf "%-20s %14s %14s %14s %14s\n" \
  "Benchmark" "Baseline(ms)" "TSO(ms)" "PSO(ms)" "Naive(ms)"
printf "%-20s %14s %14s %14s %14s\n" \
  "---------" "------------" "-------" "-------" "---------"

for ir in "$IR_DIR"/*.ll; do
  name="$(basename "$ir" .ll)"

  bin_base="$TMP/${name}_base"
  bin_tso="$TMP/${name}_tso"
  bin_pso="$TMP/${name}_pso"
  bin_naive="$TMP/${name}_naive"

  compile_ir        "$bin_base"  "$ir"
  compile_with_pass "$bin_tso"   "$PLUGIN_MAIN"  FencePassTSO "$ir"
  compile_with_pass "$bin_pso"   "$PLUGIN_MAIN"  FencePassPSO "$ir"
  compile_with_pass "$bin_naive" "$PLUGIN_NAIVE" FencePass    "$ir"

  t_base=$(measure_cpu_ms  "$bin_base")
  t_tso=$(measure_cpu_ms   "$bin_tso")
  t_pso=$(measure_cpu_ms   "$bin_pso")
  t_naive=$(measure_cpu_ms "$bin_naive")

  printf "%-20s %14s %14s %14s %14s\n" \
    "$name" "$t_base" "$t_tso" "$t_pso" "$t_naive"
done
