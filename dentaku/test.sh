#!/bin/bash

# 関数呼び出しテスト用ヘルパーをオブジェクトファイルにコンパイル
cat <<EOF > functest.c
#include <stdio.h>
int retthree() { return 3; }
int retfive() { return 5; }
void printok() { printf("OK\n"); }
int add(int x, int y) { return x + y; }
int mul(int x, int y) { return x * y; }
void printsum(int x, int y) { printf("%d\n", x + y); }
int addthree(int a, int b, int c) { return a + b + c; }
void printint(int n) { printf("%d\n", n); }
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

assert 0  'main() { return 0; }'
assert 42 'main() { return 42; }'
assert 21 'main() { return 5+20-4; }'
assert 41 'main() { return 12 + 34 - 5; }'
assert 47 'main() { return 5+6*7; }'
assert 15 'main() { return 5*(9-6); }'
assert 4  'main() { return (3+5)/2; }'
assert 10 'main() { return -10+20; }'
assert 15 'main() { return -(-5*3); }'

assert 0 'main() { return 0==1; }'
assert 1 'main() { return 42==42; }'
assert 1 'main() { return 0!=1; }'
assert 0 'main() { return 42!=42; }'

assert 1 'main() { return 0<1; }'
assert 0 'main() { return 1<1; }'
assert 0 'main() { return 2<1; }'
assert 1 'main() { return 0<=1; }'
assert 1 'main() { return 1<=1; }'
assert 0 'main() { return 2<=1; }'

assert 1 'main() { return 1>0; }'
assert 0 'main() { return 1>1; }'
assert 0 'main() { return 1>2; }'
assert 1 'main() { return 1>=0; }'
assert 1 'main() { return 1>=1; }'
assert 0 'main() { return 1>=2; }'

# 変数への代入と参照
assert 3 'main() { a=3; return a; }'
assert 0 'main() { a=0; return a; }'
assert 7 'main() { a=7; b=a; return b; }'

# 複数の変数を独立して扱える
assert 5 'main() { a=3; b=2; return a+b; }'
assert 1 'main() { a=3; b=2; return a-b; }'
assert 6 'main() { a=3; b=2; return a*b; }'

# 変数を使った演算結果を別の変数に代入
assert 10 'main() { a=3; b=7; c=a+b; return c; }'
assert 6  'main() { a=2; b=3; c=a*b; return c; }'

# 変数への再代入（上書き）
assert 5 'main() { a=3; a=5; return a; }'
assert 4 'main() { a=1; a=a+3; return a; }'

# 変数を使った比較演算
assert 1 'main() { a=3; return a==3; }'
assert 0 'main() { a=3; return a==4; }'
assert 1 'main() { a=3; b=4; return a<b; }'
assert 0 'main() { a=3; b=4; return a>b; }'
assert 1 'main() { a=5; b=5; return a<=b; }'
assert 1 'main() { a=5; b=5; return a>=b; }'

# 変数を含む複雑な式
assert 12 'main() { a=2; b=3; return a+b*a+a*b-a; }'
assert 1  'main() { a=10; b=5; return a/b==2; }'

# 複数文字の変数名
assert 3  'main() { foo=3; return foo; }'
assert 7  'main() { foo=3; bar=4; return foo+bar; }'
assert 10 'main() { abc=10; return abc; }'
assert 5  'main() { hoge=5; return hoge; }'

# 1文字変数と複数文字変数の共存
assert 8  'main() { a=3; foo=5; return a+foo; }'
assert 8  'main() { x=2; myvar=4; return x*myvar; }'

# 複数文字変数への再代入
assert 9  'main() { foo=3; foo=foo*3; return foo; }'

# 複数文字変数を使った比較
assert 1  'main() { foo=3; bar=4; return foo<bar; }'
assert 0  'main() { foo=5; bar=3; return foo<bar; }'

# return文
assert 5  'main() { return 5; }'
assert 14 'main() { return 2+3*4; }'
assert 3  'main() { a=3; return a; }'
assert 7  'main() { a=3; b=4; return a+b; }'

# return後の文は実行されない
assert 5  'main() { return 5; return 10; }'
assert 3  'main() { a=3; return a; a=100; a; }'

# if文
assert 1 'main() { if (1) return 1; return 0; }'
assert 0 'main() { if (0) return 1; return 0; }'
assert 2 'main() { if (1) return 2; else return 3; }'
assert 3 'main() { if (0) return 2; else return 3; }'
assert 5 'main() { a=5; if (a) return a; return 0; }'
assert 2 'main() { a=2; if (a==1) return 1; else if (a==2) return 2; else return 3; }'

# while文
assert 5 'main() { i=0; while(i<5) i=i+1; return i; }'
assert 0 'main() { i=0; while(i<0) i=i+1; return i; }'

# for文
assert 5  'main() { for(i=0; i<5; i=i+1) i=i; return i; }'
assert 10 'main() { sum=0; for(i=0; i<5; i=i+1) sum=sum+i; return sum; }'
assert 5  'main() { i=3; for(; i<5; i=i+1) i=i; return i; }'

# {}ブロック
assert 3  'main() { { a=3; } return a; }'
assert 3  'main() { { a=1; b=2; } return a+b; }'
assert 2  'main() { if (1) { a=1; a=a+1; } return a; }'
assert 5  'main() { if (0) { a=1; } else { a=5; } return a; }'
assert 3  'main() { i=0; while(i<3) { i=i+1; } return i; }'
assert 10 'main() { sum=0; for(i=1; i<=4; i=i+1) { sum=sum+i; } return sum; }'
assert 3  'main() { { a=1; { b=2; } } return a+b; }'

# 引数なし関数呼び出し（戻り値の検証）
assert 3 'main() { return retthree(); }'
assert 5 'main() { return retfive(); }'
assert 8 'main() { return retthree() + retfive(); }'
assert 3 'main() { a=retthree(); return a; }'
assert 1 'main() { if (retthree()==3) return 1; return 0; }'

# 引数なし関数呼び出し（実際に呼ばれたかstdoutで確認）
assert_out "OK" 'main() { printok(); return 0; }'
assert_out "OK" 'main() { if (1) printok(); return 0; }'
assert_out "OK" 'main() { i=0; while(i<1) { printok(); i=i+1; } return 0; }'

# 引数あり関数呼び出し（戻り値の検証）
assert 5  'main() { return add(2, 3); }'
assert 6  'main() { return mul(2, 3); }'
assert 10 'main() { return add(3, 7); }'
assert 6  'main() { return addthree(1, 2, 3); }'
assert 5  'main() { a=2; b=3; return add(a, b); }'
assert 7  'main() { return add(retthree(), retfive()-1); }'

# 引数あり関数呼び出し（実際に呼ばれたかstdoutで確認）
assert_out "5"  'main() { printsum(2, 3); return 0; }'
assert_out "10" 'main() { a=3; b=7; printsum(a, b); return 0; }'
assert_out "5"  'main() { printsum(retthree(), retfive()-3); return 0; }'

# 関数定義（自前の関数を定義して呼ぶ）
assert 7  'myaad(x, y) { return x + y; } main() { return myaad(3, 4); }'
assert 6  'double(x) { return x + x; } main() { return double(3); }'
assert 10 'double(x) { return x + x; } main() { a=5; return double(a); }'

# 再帰によるフィボナッチ（戻り値検証）
assert 0  'fib(n) { if (n<=1) return n; return fib(n-1)+fib(n-2); } main() { return fib(0); }'
assert 1  'fib(n) { if (n<=1) return n; return fib(n-1)+fib(n-2); } main() { return fib(1); }'
assert 1  'fib(n) { if (n<=1) return n; return fib(n-1)+fib(n-2); } main() { return fib(2); }'
assert 2  'fib(n) { if (n<=1) return n; return fib(n-1)+fib(n-2); } main() { return fib(3); }'
assert 55 'fib(n) { if (n<=1) return n; return fib(n-1)+fib(n-2); } main() { return fib(10); }'

# フィボナッチ数列の表示（n=0..7）
assert_out "$(printf '0\n1\n1\n2\n3\n5\n8\n13')" \
  'fib(n) { if (n<=1) return n; return fib(n-1)+fib(n-2); } main() { i=0; while(i<=7) { printint(fib(i)); i=i+1; } return 0; }'

echo OK