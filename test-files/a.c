int f(int a, int b) {
    int n = 0;
    if (a == 2) {
        n = a;
    } else if (b == 3) {
        n = a + b;
    }
    return n;
}

int main() {
    return f(2, 3);
}