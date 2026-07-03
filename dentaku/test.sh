#!/bin/bash

# 関数呼び出しテスト用ヘルパーをオブジェクトファイルにコンパイル
cat <<EOF > functest.c
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

# 四則演算・優先順位・括弧・単項マイナス
assert 0  'int main() { return 0; }'
assert 47 'int main() { return 5+6*7; }'
assert 4  'int main() { return (3+5)/2; }'
assert 15 'int main() { return -(-5*3); }'

# 比較演算子
assert 1 'int main() { return 1==1; }'
assert 1 'int main() { return 1!=2; }'
assert 1 'int main() { return 1<2; }'
assert 1 'int main() { return 2<=2; }'
assert 1 'int main() { return 2>1; }'
assert 1 'int main() { return 2>=2; }'

# 変数宣言・代入・複数文字変数名
assert 7  'int main() { int a; int b; a=3; b=4; return a+b; }'
assert 4  'int main() { int a; a=1; a=a+3; return a; }'
assert 3  'int main() { int foo; foo=3; return foo; }'
assert 12 'int main() { int a; int b; a=2; b=3; return a+b*a+a*b-a; }'

# return後の文は実行されない
assert 5  'int main() { return 5; return 10; }'

# if文
assert 2 'int main() { if (1) return 2; else return 3; }'
assert 2 'int main() { int a; a=2; if (a==1) return 1; else if (a==2) return 2; else return 3; }'

# while文
assert 5 'int main() { int i; i=0; while(i<5) i=i+1; return i; }'

# for文（省略可能な節も確認）
assert 10 'int main() { int sum; int i; sum=0; for(i=0; i<5; i=i+1) sum=sum+i; return sum; }'
assert 5  'int main() { int i; i=3; for(; i<5; i=i+1) i=i; return i; }'

# {}ブロック（ifとの組み合わせ・ネスト）
assert 2 'int main() { int a; if (1) { a=1; a=a+1; } return a; }'
assert 3 'int main() { int a; int b; { a=1; { b=2; } } return a+b; }'

# 外部関数呼び出し（引数なし/あり、戻り値・副作用の両方）
assert 3 'int main() { return retthree(); }'
assert_out "OK" 'int main() { printok(); return 0; }'
assert 5 'int main() { return add(2, 3); }'
assert_out "5" 'int main() { printsum(2, 3); return 0; }'
assert 6 'int main() { return addthree(1, 2, 3); }'

# 自前の関数定義
assert 7 'int myadd(int x, int y) { return x + y; } int main() { return myadd(3, 4); }'

# 再帰（基底ケースと再帰ケース）
assert 1  'int fib(int n) { if (n<=1) return n; return fib(n-1)+fib(n-2); } int main() { return fib(1); }'
assert 55 'int fib(int n) { if (n<=1) return n; return fib(n-1)+fib(n-2); } int main() { return fib(10); }'

# 単項 & と単項 *
assert 5  'int main() { int a; int *p; a=5; p=&a; return *p; }'
assert 10 'int main() { int a; int *p; a=5; p=&a; *p=10; return a; }'

# ポインタの加減算（外部ヘルパーallocfourで連続領域を確保してテスト）
assert 4 'int main() { int *p; int *q; allocfour(&p, 1, 2, 4, 8); q = p + 2; return *q; }'
assert 1 'int main() { int *p; int *q; allocfour(&p, 1, 2, 4, 8); q = p + 3; q = q - 3; return *q; }'

# sizeof演算子
assert 4 'int main() { int a; return sizeof(a); }'
assert 8 'int main() { int *p; return sizeof(p); }'
assert 5 'int main() { int a; return sizeof(a) + 1; }'

# 配列の変数定義（添字アクセスは未実装のため、宣言が通ることと領域確保の正しさのみ確認）
assert 0  'int main() { int a[10]; return 0; }'
assert 99 'int main() { int a[3]; int b; b=99; return b; }'

echo OK
