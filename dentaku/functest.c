#include <stdio.h>
#include <stdlib.h>
int retthree() { return 3; }
int retfive() { return 5; }
void printok() { printf("OK\n"); }
int add(int x, int y) { return x + y; }
int mul(int x, int y) { return x * y; }
void printsum(int x, int y) { printf("%d\n", x + y); }
int addthree(int a, int b, int c) { return a + b + c; }
void printint(int n) { printf("%d\n", n); }
int *allocfour(int **p, int a, int b, int c, int d) {
  int *q = malloc(4 * sizeof(int));
  q[0] = a;
  q[1] = b;
  q[2] = c;
  q[3] = d;
  *p = q;
  return q;
}
