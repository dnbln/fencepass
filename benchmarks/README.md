# FencePass Benchmark Evaluation

This directory contains a small benchmark suite for evaluating the `FencePass` LLVM plugin, which synthesizes `seq_cst` memory fences around memory accesses to enforce sequential consistency.

## Prerequisites

- LLVM 20 (`opt-20`, `clang-20` / `clang++` from `/usr/lib/llvm-20/bin/`)
- The plugin built against LLVM 20's `libstdc++` (see build note below)

### Build note

The plugin **must** be built with the LLVM 20 toolchain and without `-stdlib=libc++`, otherwise `opt-20` will crash with an ABI mismatch. From the repo root:

```sh
cd build
rm -f CMakeCache.txt
cmake .. \
  -DLLVM_INSTALL_DIR=/usr/lib/llvm-20 \
  -DCMAKE_CXX_COMPILER=/usr/lib/llvm-20/bin/clang++ \
  -DCMAKE_CXX_FLAGS="" \
  -DCMAKE_EXE_LINKER_FLAGS="" \
  -DCMAKE_SHARED_LINKER_FLAGS=""
make -j$(nproc)
```

## Benchmarks

| File | Description |
|---|---|
| `src/bubblesort.c` | Bubble sort on a 1024-element array |
| `src/fibonacci.c` | Iterative Fibonacci (array-based, up to index 90) |
| `src/linked_list.c` | Linked list construction and sum (1000 nodes) |
| `src/matrix_mul.c` | 64×64 double-precision matrix multiplication |
| `src/quicksort.c` | Quicksort on a 2048-element array |
| `src/strlen_count.c` | Repeated `strlen` calls on static strings (100k reps) |

These cover a range of memory access patterns: array reads/writes, pointer chasing, and call-heavy code with no visible memory accesses after optimization.

## Running

### 1. Compile benchmarks to LLVM IR

```sh
for f in src/*.c; do
  name=$(basename "$f" .c)
  /usr/lib/llvm-20/bin/clang-20 -O1 -emit-llvm -S "$f" -o "ir/${name}.ll"
done
```

### 2. Run the FencePass plugin

```sh
PLUGIN=../build/libFencePass.so
for f in ir/*.ll; do
  name=$(basename "$f" .ll)
  opt-20 -load-pass-plugin "$PLUGIN" -passes=FencePass "$f" -S -o "out/${name}_fenced.ll"
done
```

Output IR is written to `out/`.

## Results

Compiled at `-O1`. Fence counts reflect the pass output after redundancy elimination.

| Benchmark | Mem accesses (IR) | Fences inserted | Instructions before | Instructions after |
|---|---|---|---|---|
| bubblesort | 5 | 11 | 60 | 71 |
 fibonacci | 6 | 10 | 37 | 47 |
| linked_list | 4 | 8 | 37 | 45 |
| matrix_mul | 4 | 9 | 69 | 78 |
| quicksort | 5 | 12 | 53 | 65 |
| strlen_count | 0 | 0 | 18 | 18 |

### Notes

- **`strlen_count`** receives zero fences: at `-O1`, all memory accesses in its hot loop are either inlined or not visible as `load`/`store` instructions, so the pass has nothing to instrument. This is correct behavior.
- Fences per memory access averages ~2 (one before, one after each access), with some consolidation from the redundancy elimination passes built into `FencePass`.
- The instruction overhead ranges from **+18% to +27%** across the benchmarks that have instrumented accesses.
