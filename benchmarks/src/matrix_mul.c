#include <stdio.h>
#define N 64

double A[N][N], B[N][N], C[N][N];

void matmul() {
    for (int i = 0; i < N; i++)
        for (int j = 0; j < N; j++) {
            double sum = 0.0;
            for (int k = 0; k < N; k++)
                sum += A[i][k] * B[k][j];
            C[i][j] = sum;
        }
}

int main() {
    for (int i = 0; i < N; i++)
        for (int j = 0; j < N; j++) {
            A[i][j] = i + j;
            B[i][j] = i - j;
        }
    matmul();
    printf("C[0][0] = %f\n", C[0][0]);
    return 0;
}
