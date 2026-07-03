#include <stdio.h>
#include <stdlib.h>
int retthree() { return 3; }
void printok() { printf("OK\n"); }
int add(int x, int y) { return x + y; }
void printsum(int x, int y) { printf("%d\n", x + y); }
int addthree(int a, int b, int c) { return a + b + c; }
int *allocfour(int **p, int a, int b, int c, int d) {
  int *q = malloc(4 * sizeof(int));
  q[0] = a;
  q[1] = b;
  q[2] = c;
  q[3] = d;
  *p = q;
  return q;
}
