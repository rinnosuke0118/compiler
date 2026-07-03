#!/bin/bash

# 関数呼び出しテスト用ヘルパーをオブジェクトファイルにコンパイル
cat <<EOF > functest.c
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
EOF
cc -c -o functest.o functest.c

# 終了コードを検証するアサーション
assert(){
    expected="$1"
    input="$2"

    ./9cc "$input" > tmp.s
    cc -o tmp tmp.s functest.o
    ./tmp
    actual="$?"

    if [ "$actual" = "$expected" ]; then
        echo "$input => $actual"
    else
        echo "$input => $expected expected, but got $actual"
        exit 1
    fi
}

# 標準出力を検証するアサーション（関数が実際に呼ばれたか確認）
assert_out(){
    expected="$1"
    input="$2"

    ./9cc "$input" > tmp.s
    cc -o tmp tmp.s functest.o
    actual=$(./tmp)

    if [ "$actual" = "$expected" ]; then
        echo "$input => '$actual'"
    else
        echo "$input => '$expected' expected, but got '$actual'"
        exit 1
    fi
}

assert 0  'int main() { return 0; }'
assert 42 'int main() { return 42; }'
assert 21 'int main() { return 5+20-4; }'
assert 41 'int main() { return 12 + 34 - 5; }'
assert 47 'int main() { return 5+6*7; }'
assert 15 'int main() { return 5*(9-6); }'
assert 4  'int main() { return (3+5)/2; }'
assert 10 'int main() { return -10+20; }'
assert 15 'int main() { return -(-5*3); }'

assert 0 'int main() { return 0==1; }'
assert 1 'int main() { return 42==42; }'
assert 1 'int main() { return 0!=1; }'
assert 0 'int main() { return 42!=42; }'

assert 1 'int main() { return 0<1; }'
assert 0 'int main() { return 1<1; }'
assert 0 'int main() { return 2<1; }'
assert 1 'int main() { return 0<=1; }'
assert 1 'int main() { return 1<=1; }'
assert 0 'int main() { return 2<=1; }'

assert 1 'int main() { return 1>0; }'
assert 0 'int main() { return 1>1; }'
assert 0 'int main() { return 1>2; }'
assert 1 'int main() { return 1>=0; }'
assert 1 'int main() { return 1>=1; }'
assert 0 'int main() { return 1>=2; }'

# 変数宣言と代入
assert 3 'int main() { int a; a=3; return a; }'
assert 0 'int main() { int a; a=0; return a; }'
assert 7 'int main() { int a; int b; a=7; b=a; return b; }'

# 複数の変数を独立して扱える
assert 5 'int main() { int a; int b; a=3; b=2; return a+b; }'
assert 1 'int main() { int a; int b; a=3; b=2; return a-b; }'
assert 6 'int main() { int a; int b; a=3; b=2; return a*b; }'

# 変数を使った演算結果を別の変数に代入
assert 10 'int main() { int a; int b; int c; a=3; b=7; c=a+b; return c; }'
assert 6  'int main() { int a; int b; int c; a=2; b=3; c=a*b; return c; }'

# 変数への再代入（上書き）
assert 5 'int main() { int a; a=3; a=5; return a; }'
assert 4 'int main() { int a; a=1; a=a+3; return a; }'

# 変数を使った比較演算
assert 1 'int main() { int a; a=3; return a==3; }'
assert 0 'int main() { int a; a=3; return a==4; }'
assert 1 'int main() { int a; int b; a=3; b=4; return a<b; }'
assert 0 'int main() { int a; int b; a=3; b=4; return a>b; }'
assert 1 'int main() { int a; int b; a=5; b=5; return a<=b; }'
assert 1 'int main() { int a; int b; a=5; b=5; return a>=b; }'

# 変数を含む複雑な式
assert 12 'int main() { int a; int b; a=2; b=3; return a+b*a+a*b-a; }'
assert 1  'int main() { int a; int b; a=10; b=5; return a/b==2; }'

# 複数文字の変数名
assert 3  'int main() { int foo; foo=3; return foo; }'
assert 7  'int main() { int foo; int bar; foo=3; bar=4; return foo+bar; }'
assert 10 'int main() { int abc; abc=10; return abc; }'
assert 5  'int main() { int hoge; hoge=5; return hoge; }'

# 1文字変数と複数文字変数の共存
assert 8  'int main() { int a; int foo; a=3; foo=5; return a+foo; }'
assert 8  'int main() { int x; int myvar; x=2; myvar=4; return x*myvar; }'

# 複数文字変数への再代入
assert 9  'int main() { int foo; foo=3; foo=foo*3; return foo; }'

# 複数文字変数を使った比較
assert 1  'int main() { int foo; int bar; foo=3; bar=4; return foo<bar; }'
assert 0  'int main() { int foo; int bar; foo=5; bar=3; return foo<bar; }'

# return文
assert 5  'int main() { return 5; }'
assert 14 'int main() { return 2+3*4; }'
assert 3  'int main() { int a; a=3; return a; }'
assert 7  'int main() { int a; int b; a=3; b=4; return a+b; }'

# return後の文は実行されない
assert 5  'int main() { return 5; return 10; }'
assert 3  'int main() { int a; a=3; return a; a=100; a; }'

# if文
assert 1 'int main() { if (1) return 1; return 0; }'
assert 0 'int main() { if (0) return 1; return 0; }'
assert 2 'int main() { if (1) return 2; else return 3; }'
assert 3 'int main() { if (0) return 2; else return 3; }'
assert 5 'int main() { int a; a=5; if (a) return a; return 0; }'
assert 2 'int main() { int a; a=2; if (a==1) return 1; else if (a==2) return 2; else return 3; }'

# while文
assert 5 'int main() { int i; i=0; while(i<5) i=i+1; return i; }'
assert 0 'int main() { int i; i=0; while(i<0) i=i+1; return i; }'

# for文
assert 5  'int main() { int i; for(i=0; i<5; i=i+1) i=i; return i; }'
assert 10 'int main() { int sum; int i; sum=0; for(i=0; i<5; i=i+1) sum=sum+i; return sum; }'
assert 5  'int main() { int i; i=3; for(; i<5; i=i+1) i=i; return i; }'

# {}ブロック
assert 3  'int main() { int a; { a=3; } return a; }'
assert 3  'int main() { int a; int b; { a=1; b=2; } return a+b; }'
assert 2  'int main() { int a; if (1) { a=1; a=a+1; } return a; }'
assert 5  'int main() { int a; if (0) { a=1; } else { a=5; } return a; }'
assert 3  'int main() { int i; i=0; while(i<3) { i=i+1; } return i; }'
assert 10 'int main() { int sum; int i; sum=0; for(i=1; i<=4; i=i+1) { sum=sum+i; } return sum; }'
assert 3  'int main() { int a; int b; { a=1; { b=2; } } return a+b; }'

# 引数なし外部関数呼び出し（戻り値の検証）
assert 3 'int main() { return retthree(); }'
assert 5 'int main() { return retfive(); }'
assert 8 'int main() { return retthree() + retfive(); }'
assert 3 'int main() { int a; a=retthree(); return a; }'
assert 1 'int main() { if (retthree()==3) return 1; return 0; }'

# 引数なし外部関数呼び出し（実際に呼ばれたかstdoutで確認）
assert_out "OK" 'int main() { printok(); return 0; }'
assert_out "OK" 'int main() { if (1) printok(); return 0; }'
assert_out "OK" 'int main() { int i; i=0; while(i<1) { printok(); i=i+1; } return 0; }'

# 引数あり外部関数呼び出し（戻り値の検証）
assert 5  'int main() { return add(2, 3); }'
assert 6  'int main() { return mul(2, 3); }'
assert 10 'int main() { return add(3, 7); }'
assert 6  'int main() { return addthree(1, 2, 3); }'
assert 5  'int main() { int a; int b; a=2; b=3; return add(a, b); }'
assert 7  'int main() { return add(retthree(), retfive()-1); }'

# 引数あり外部関数呼び出し（実際に呼ばれたかstdoutで確認）
assert_out "5"  'int main() { printsum(2, 3); return 0; }'
assert_out "10" 'int main() { int a; int b; a=3; b=7; printsum(a, b); return 0; }'
assert_out "5"  'int main() { printsum(retthree(), retfive()-3); return 0; }'

# 関数定義（自前の関数を定義して呼ぶ）
assert 7  'int myadd(int x, int y) { return x + y; } int main() { return myadd(3, 4); }'
assert 6  'int dbl(int x) { return x + x; } int main() { return dbl(3); }'
assert 10 'int dbl(int x) { return x + x; } int main() { int a; a=5; return dbl(a); }'

# 再帰によるフィボナッチ（戻り値検証）
assert 0  'int fib(int n) { if (n<=1) return n; return fib(n-1)+fib(n-2); } int main() { return fib(0); }'
assert 1  'int fib(int n) { if (n<=1) return n; return fib(n-1)+fib(n-2); } int main() { return fib(1); }'
assert 1  'int fib(int n) { if (n<=1) return n; return fib(n-1)+fib(n-2); } int main() { return fib(2); }'
assert 2  'int fib(int n) { if (n<=1) return n; return fib(n-1)+fib(n-2); } int main() { return fib(3); }'
assert 55 'int fib(int n) { if (n<=1) return n; return fib(n-1)+fib(n-2); } int main() { return fib(10); }'

# フィボナッチ数列の表示（n=0..7）
assert_out "$(printf '0\n1\n1\n2\n3\n5\n8\n13')" \
  'int fib(int n) { if (n<=1) return n; return fib(n-1)+fib(n-2); } int main() { int i; i=0; while(i<=7) { printint(fib(i)); i=i+1; } return 0; }'

# 単項 & と単項 *
assert 5  'int main() { int a; int *p; a=5; p=&a; return *p; }'
assert 10 'int main() { int a; int *p; a=5; p=&a; *p=10; return a; }'
assert 7  'int main() { int a; a=7; return *&a; }'
assert 20 'int main() { int a; int *p; a=10; p=&a; a=20; return *p; }'

# ポインタの加減算（外部ヘルパーallocfourで連続領域を確保してテスト）
assert 4 'int main() { int *p; int *q; allocfour(&p, 1, 2, 4, 8); q = p + 2; return *q; }'
assert 8 'int main() { int *p; int *q; allocfour(&p, 1, 2, 4, 8); q = p + 3; return *q; }'
assert 1 'int main() { int *p; int *q; allocfour(&p, 1, 2, 4, 8); q = p + 3; q = q - 3; return *q; }'
assert 2 'int main() { int *p; int *q; allocfour(&p, 1, 2, 4, 8); q = p + 3; q = q - 2; return *q; }'

echo OK
