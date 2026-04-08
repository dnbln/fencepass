#include <stdio.h>

long long fib[100];

void compute_fib(int n) {
    fib[0] = 0;
    fib[1] = 1;
    for (int i = 2; i <= n; i++)
        fib[i] = fib[i - 1] + fib[i - 2];
}

int main() {
    compute_fib(90);
    printf("fib[90] = %lld\n", fib[90]);
    return 0;
}
