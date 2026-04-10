#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
SUITE_DIR="${TEST_SUITE_DIR:-$REPO/llvm-test-suite}"
BASE_BUILD_ROOT="${BENCH_BUILD_ROOT:-$REPO/test-suite-builds}"
CLANG_BIN="${CLANG_BIN:-$(command -v clang)}"
LLVM_LIT_BIN="${LLVM_LIT_BIN:-$(command -v llvm-lit || command -v lit || true)}"
BENCH_RUNS="${BENCH_RUNS:-5}"
LLVM_SIZE_BIN="${LLVM_SIZE_BIN:-$(command -v llvm-size || true)}"

BENCHMARK_SUBDIRS=(
  'SingleSource/Benchmarks/Stanford'
  'SingleSource/Benchmarks/Misc'
  'SingleSource/Benchmarks/Polybench/linear-algebra/kernels/3mm'
)

BENCHMARK_TARGETS=(
  Treesort
  richards_benchmark
  oourafft
  fbench
  3mm
)

BENCHMARK_TEST_PATHS=(
  'SingleSource/Benchmarks/Stanford/Treesort.test'
  'SingleSource/Benchmarks/Misc/richards_benchmark.test'
  'SingleSource/Benchmarks/Misc/oourafft.test'
  'SingleSource/Benchmarks/Misc/fbench.test'
  'SingleSource/Benchmarks/Polybench/linear-algebra/kernels/3mm/3mm.test'
)

SOURCE_FILTERS=(
  '/SingleSource/Benchmarks/Stanford/'
  '/SingleSource/Benchmarks/Misc/'
  '/SingleSource/Benchmarks/Polybench/linear-algebra/kernels/3mm/'
)

if [[ ! -d "$SUITE_DIR" ]]; then
  echo "bench_llvm.sh: llvm-test-suite not found at $SUITE_DIR" >&2
  exit 1
fi

if [[ ! -x "$CLANG_BIN" ]]; then
  echo "bench_llvm.sh: clang not found" >&2
  exit 1
fi

if [[ -z "$LLVM_LIT_BIN" ]]; then
  echo "bench_llvm.sh: llvm-lit not found in PATH" >&2
  exit 1
fi

mkdir -p "$BASE_BUILD_ROOT"

run_once() {
  local mode="$1"
  local compiler="$2"
  local run_index="$3"
  local build_dir="$BASE_BUILD_ROOT/$mode/run-$run_index"
  local suite_subdirs
  local source_filters
  local lit_targets=()
  local test_path

  suite_subdirs="$(IFS=';'; echo "${BENCHMARK_SUBDIRS[*]}")"
  source_filters="$(IFS=':'; echo "${SOURCE_FILTERS[*]}")"

  export FENCEPASS_SOURCE_SUBDIRS="$source_filters"
  export FENCEPASS_MODE="$mode"

  rm -rf "$build_dir"

  local code_size_args=()
  if [[ -n "$LLVM_SIZE_BIN" ]]; then
    code_size_args=(
      -DTEST_SUITE_COLLECT_CODE_SIZE=ON
      -DTEST_SUITE_LLVM_SIZE="$LLVM_SIZE_BIN"
    )
  else
    code_size_args=(
      -DTEST_SUITE_COLLECT_CODE_SIZE=OFF
    )
  fi

  cmake -S "$SUITE_DIR" -B "$build_dir" \
    -DCMAKE_C_COMPILER="$compiler" \
    -C"$SUITE_DIR/cmake/caches/O3.cmake" \
    -DTEST_SUITE_SUBDIRS="$suite_subdirs" \
    -DTEST_SUITE_COLLECT_COMPILE_TIME=ON \
    -DTEST_SUITE_RUN_BENCHMARKS=ON \
    "${code_size_args[@]}"

  cmake --build "$build_dir" --target \
    fpcmp-target \
    timeit-target \
    not \
    build-litsupport \
    build-fpcmp \
    build-HashProgramOutput.sh \
    build-timeit \
    "${BENCHMARK_TARGETS[@]}"

  mkdir -p "$build_dir/SingleSource"
  cat > "$build_dir/SingleSource/lit.local.cfg" <<'EOF'
config.traditional_output = True
config.single_source = True
EOF

  for test_path in "${BENCHMARK_TEST_PATHS[@]}"; do
    lit_targets+=("$build_dir/$test_path")
  done

  "$LLVM_LIT_BIN" -v -j 1 \
    -o "$build_dir/results.json" \
    "${lit_targets[@]}"

  unset FENCEPASS_MODE
  unset FENCEPASS_SOURCE_SUBDIRS
}

run_mode() {
  local mode="$1"
  local compiler="$2"
  local run_index

  for ((run_index = 1; run_index <= BENCH_RUNS; ++run_index)); do
    echo "=== $mode run $run_index/$BENCH_RUNS ==="
    run_once "$mode" "$compiler" "$run_index"
  done
}

print_summary() {
  python3 - "$BASE_BUILD_ROOT" "$BENCH_RUNS" <<'EOF'
import json
import os
import statistics
import sys

base = sys.argv[1]
runs = int(sys.argv[2])
modes = ["baseline", "tso", "pso", "naive"]
benchmark_order = ["Treesort", "richards_benchmark", "oourafft", "fbench", "3mm"]


def benchmark_name(test_entry):
  name = test_entry["name"]
  stem = name.rsplit("/", 1)[-1]
  return stem.removesuffix(".test")


def load_run_metrics(mode, run):
  result_path = os.path.join(base, mode, f"run-{run}", "results.json")
  with open(result_path, "r", encoding="utf-8") as handle:
    data = json.load(handle)

  metrics_by_benchmark = {}
  for test in data["tests"]:
    metrics_by_benchmark[benchmark_name(test)] = test["metrics"]
  return metrics_by_benchmark

print()
has_size = False
run_cache = {}
for mode in modes:
  for run in range(1, runs + 1):
    run_cache[(mode, run)] = load_run_metrics(mode, run)
    if any("size" in metrics for metrics in run_cache[(mode, run)].values()):
      has_size = True
      break
  if has_size:
    break

header = f"{'Benchmark':<12} {'Mode':<10} {'Compile(avg)':>14} {'Exec(avg)':>12} {'Link(avg)':>12}"
underline = f"{'---------':<12} {'----':<10} {'------------':>14} {'---------':>12} {'---------':>12}"
if has_size:
  header += f" {'Size(avg)':>12}"
  underline += f" {'---------':>12}"

print(header)
print(underline)

for benchmark in benchmark_order:
  for mode in modes:
    compile_times = []
    exec_times = []
    link_times = []
    sizes = []
    for run in range(1, runs + 1):
      metrics = run_cache[(mode, run)][benchmark]
      compile_times.append(metrics["compile_time"])
      exec_times.append(metrics["exec_time"])
      link_times.append(metrics["link_time"])
      if "size" in metrics:
        sizes.append(metrics["size"])

    row = f"{benchmark:<12} {mode:<10} {statistics.mean(compile_times):>14.4f} {statistics.mean(exec_times):>12.4f} {statistics.mean(link_times):>12.4f}"
    if has_size:
      size_value = statistics.mean(sizes) if sizes else float('nan')
      row += f" {size_value:>12.1f}"
    print(row)
EOF
}

run_mode baseline "$REPO/clang-pass-wrapper.sh"
run_mode tso "$REPO/clang-pass-wrapper.sh"
run_mode pso "$REPO/clang-pass-wrapper.sh"
run_mode naive "$REPO/clang-pass-wrapper.sh"

print_summary

cat <<EOF
Finished selected benchmark runs.

Per-run result files:
  $BASE_BUILD_ROOT/<mode>/run-<n>/results.json

Compare them with:
  $SUITE_DIR/utils/compare.py \
    $BASE_BUILD_ROOT/baseline/run-1/results.json \
    $BASE_BUILD_ROOT/tso/run-1/results.json \
    $BASE_BUILD_ROOT/pso/run-1/results.json \
    $BASE_BUILD_ROOT/naive/run-1/results.json

  Benchmarks included: Treesort, richards_benchmark, oourafft, fbench, 3mm.
  Set BENCH_RUNS to change the repetition count.
Set LLVM_SIZE_BIN to the llvm-size path if it is not on PATH.
EOF