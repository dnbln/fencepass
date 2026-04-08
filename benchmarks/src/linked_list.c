#include <stdio.h>
#include <stdlib.h>

typedef struct Node {
    int val;
    struct Node *next;
} Node;

Node *push(Node *head, int val) {
    Node *n = malloc(sizeof(Node));
    n->val = val;
    n->next = head;
    return n;
}

int sum(Node *head) {
    int s = 0;
    while (head) {
        s += head->val;
        head = head->next;
    }
    return s;
}

int main() {
    Node *list = NULL;
    for (int i = 0; i < 1000; i++)
        list = push(list, i);
    printf("sum = %d\n", sum(list));
    return 0;
}
