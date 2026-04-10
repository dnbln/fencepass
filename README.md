# FencePass

An LLVM compiler pass that automatically inserts memory fences into programs to enforce memory consistency guarantees.

## What it does

Modern CPUs and compilers are allowed to reorder memory operations (loads and stores) for performance. This is fine for single-threaded programs, but in concurrent programs it can cause bugs that are very hard to detect.

This pass analyses a program's control flow and inserts the minimum number of `seq_cst` (sequentially consistent) fences needed to prevent illegal reorderings. It supports two memory models:

- **TSO (Total Store Order)**: used by x86. Stores can be delayed past loads to different addresses. The pass prevents store-load reorderings.
- **PSO (Partial Store Order)**: a weaker model used by some RISC architectures. Stores can also be reordered with other stores to different addresses. The pass prevents both store-load and store-store reorderings.

## How the algorithm works

The pass runs a depth-first search over the control flow graph starting from every store instruction. It looks for any later memory access (load or store, depending on the model) that touches a different memory location and could therefore be reordered past the original store.

When it finds a potential reordering, it marks every instruction along that path as a candidate fence location and increments a counter for each one. The counter tracks how many reorderings a fence at that position would prevent.

After scanning the whole function, the pass picks the instruction with the highest counter and inserts a fence before it. It then repeats the whole process until there are no more reorderings to prevent.

This greedy approach does not always find the minimum possible number of fences (the problem is NP-hard in general), but it works well in practice.

## What is in this repo

```
FencePass.cpp                  the main pass (TSO and PSO modes)
FencePassBaselineNaive.cpp     a naive baseline that fences every memory access
benchmarks/                    C programs used to evaluate the pass
  src/                         source files
  ir/                          compiled LLVM IR
  out/                         IR after the pass has run
compare_passes.sh              counts how many fences each pass inserts
perf_bench.sh                  measures CPU time for each benchmark variant
bench_llvm.sh                  llvm-test-suite benchmark driver
clang-pass-wrapper.sh          shared wrapper pipeline used by all benchmark modes
```

## Requirements

- LLVM 20 (`opt-20`, `clang-20`)
- CMake 3.20 or later- `perf` (for `perf_bench.sh`)
- `bc` (for the millisecond conversion in `perf_bench.sh`)
- lit 18.8 or llvm-lit (to run the llvm test suite)

For the llvm-test-suite benchmark flow, the test suite itself is also needed locally. The script looks in `./llvm-test-suite` by default, or in `TEST_SUITE_DIR` if set. The test-suite can be cloned from https://github.com/llvm/llvm-test-suite

## Building

```bash
cmake -S . -B build \
  -DLLVM_INSTALL_DIR=/usr/lib/llvm-20 \
  -DCMAKE_CXX_COMPILER=/usr/lib/llvm-20/bin/clang++ \
  -DCMAKE_CXX_FLAGS=""
make -C build -j$(nproc)
```

This produces two shared libraries in `build/`:

- `libFencePass.so` - the main pass
- `libFencePassBaselineNaive.so` - the naive baseline

## Running the pass manually

```bash
opt-20 -load-pass-plugin build/libFencePass.so \
  -passes=FencePassTSO input.ll -S -o output.ll
```

Use `-passes=FencePassPSO` for PSO mode.

## Comparing fence counts

```bash
./compare_passes.sh
```

Prints a table showing how many fences the main pass and the naive baseline insert for each benchmark.

## Measuring CPU time

```bash
./perf_bench.sh
```

Compiles each benchmark in five variants (baseline, TSO, PSO, Naive-TSO, Naive-PSO) and measures CPU time using `perf stat`. You can control the number of repetitions with `RUNS=20 ./perf_bench.sh`.

## The naive baseline

`FencePassBaselineNaive` is a simple reference implementation. It puts a fence before and after every single load and store, then removes any consecutive duplicate fences. It inserts far more fences than needed and serves as an upper bound to compare against.

## The LLVM benchmarks and test-suite
The LLVM test-suite has only been attempted on macOS, so the commands below are intended for macOS use.

Clone the LLVM test-suite into the repo root, or set `TEST_SUITE_DIR` to an existing checkout:

```bash
git clone https://github.com/llvm/llvm-test-suite llvm-test-suite
```
Build the pass as described above.

Then run the selected LLVM benchmarks with the wrapper-based pipeline:

```bash
CLANG_BIN=/path/to/llvm-project/build-clang/bin/clang \
LLVM_INSTALL_DIR=/path/to/llvm-project/build-clang \
LLVM_LIT_BIN=/opt/homebrew/bin/lit \
BENCH_RUNS=1 \
./bench_llvm.sh
```
This runs the selected test-suite benchmarks in four modes: `baseline`, `tso`, `pso`, and `naive`.
Results are written to `test-suite-builds/<mode>/run-<n>/results.json`.

Use 
- `BENCH_RUNS` to change the number of repetitions and average the times over them.
- `LLVM_SIZE_BIN` if `llvm-size` is not already on `PATH`

The current benchmark set in `bench_llvm.sh` is:

- `Treesort`
- `richards_benchmark`
- `oourafft`
- `fbench`
- `3mm`

A table with the different compile times, execution times and linking times is generated.
