#include <stdio.h>
#include <string.h>

#define REPS 100000

static const char *strings[] = {
    "hello world",
    "the quick brown fox jumps over the lazy dog",
    "llvm fence synthesis pass evaluation",
    "sequential consistency memory model",
    "compiler optimization benchmark",
};

int main() {
    long total = 0;
    int n = sizeof(strings) / sizeof(strings[0]);
    for (int r = 0; r < REPS; r++)
        for (int i = 0; i < n; i++)
            total += strlen(strings[i]);
    printf("total = %ld\n", total);
    return 0;
}
