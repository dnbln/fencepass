#include <stdio.h>
#define N 1024

int arr[N];

void bubble_sort(int *a, int n) {
    for (int i = 0; i < n - 1; i++)
        for (int j = 0; j < n - 1 - i; j++)
            if (a[j] > a[j + 1]) {
                int tmp = a[j];
                a[j] = a[j + 1];
                a[j + 1] = tmp;
            }
}

int main() {
    for (int i = 0; i < N; i++)
        arr[i] = N - i;
    bubble_sort(arr, N);
    printf("arr[0]=%d arr[N-1]=%d\n", arr[0], arr[N - 1]);
    return 0;
}
