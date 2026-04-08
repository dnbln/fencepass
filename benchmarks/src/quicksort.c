#include <stdio.h>
#define N 2048

int arr[N];

void quicksort(int *a, int lo, int hi) {
    if (lo >= hi) return;
    int pivot = a[hi];
    int i = lo - 1;
    for (int j = lo; j < hi; j++) {
        if (a[j] <= pivot) {
            i++;
            int tmp = a[i]; a[i] = a[j]; a[j] = tmp;
        }
    }
    int tmp = a[i + 1]; a[i + 1] = a[hi]; a[hi] = tmp;
    int p = i + 1;
    quicksort(a, lo, p - 1);
    quicksort(a, p + 1, hi);
}

int main() {
    for (int i = 0; i < N; i++)
        arr[i] = N - i;
    quicksort(arr, 0, N - 1);
    printf("arr[0]=%d arr[N-1]=%d\n", arr[0], arr[N - 1]);
    return 0;
}
