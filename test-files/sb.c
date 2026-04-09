// Store Buffering 
#include <pthread.h>
#include <stdio.h>

volatile int x = 0;
volatile int y = 0;

int r1, r2;

void *t0(void *arg) {
    x = 1;      
    r1 = y;     
    return NULL;
}

void *t1(void *arg) {
    y = 1;      
    r2 = x;     
    return NULL;
}

int main() {
    int detected = 0;

    for (int i = 0; i < 1000000; i++) {
        x = y = r1 = r2 = 0;

        pthread_t th0, th1;
        pthread_create(&th0, NULL, t0, NULL);
        pthread_create(&th1, NULL, t1, NULL);

        pthread_join(th0, NULL);
        pthread_join(th1, NULL);

        if (r1 == 0 && r2 == 0) {
            detected++;
        }
    }

    printf("Store Buffering count: %d\n", detected);
}
