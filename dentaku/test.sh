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

assert 0 '0;'
assert 42 '42;'
assert 21 "5+20-4;"
assert 41 " 12 + 34 - 5 ;"
assert 47 '5+6*7;'
assert 15 '5*(9-6);'
assert 4 '(3+5)/2;'
assert 10 '-10+20;'
assert 15 '-(-5*3);'

assert 0 '0==1;'
assert 1 '42==42;'
assert 1 '0!=1;'
assert 0 '42!=42;'

assert 1 '0<1;'
assert 0 '1<1;'
assert 0 '2<1;'
assert 1 '0<=1;'
assert 1 '1<=1;'
assert 0 '2<=1;'

assert 1 '1>0;'
assert 0 '1>1;'
assert 0 '1>2;'
assert 1 '1>=0;'
assert 1 '1>=1;'
assert 0 '1>=2;'

# 変数への代入と参照
assert 3 'a=3; a;'
assert 0 'a=0; a;'
assert 7 'a=7; b=a; b;'

# 複数の変数を独立して扱える
assert 5 'a=3; b=2; a+b;'
assert 1 'a=3; b=2; a-b;'
assert 6 'a=3; b=2; a*b;'

# 変数を使った演算結果を別の変数に代入
assert 10 'a=3; b=7; c=a+b; c;'
assert 6  'a=2; b=3; c=a*b; c;'

# 変数への再代入（上書き）
assert 5 'a=3; a=5; a;'
assert 4 'a=1; a=a+3; a;'

# 変数を使った比較演算
assert 1 'a=3; a==3;'
assert 0 'a=3; a==4;'
assert 1 'a=3; b=4; a<b;'
assert 0 'a=3; b=4; a>b;'
assert 1 'a=5; b=5; a<=b;'
assert 1 'a=5; b=5; a>=b;'

# 変数を含む複雑な式
assert 12 'a=2; b=3; a+b*a+a*b-a;'
assert 1  'a=10; b=5; a/b==2;'

# 複数文字の変数名
assert 3  'foo=3; foo;'
assert 7  'foo=3; bar=4; foo+bar;'
assert 10 'abc=10; abc;'
assert 5  'hoge=5; hoge;'

# 1文字変数と複数文字変数の共存
assert 8  'a=3; foo=5; a+foo;'
assert 8  'x=2; myvar=4; x*myvar;'

# 複数文字変数への再代入
assert 9  'foo=3; foo=foo*3; foo;'

# 複数文字変数を使った比較
assert 1  'foo=3; bar=4; foo<bar;'
assert 0  'foo=5; bar=3; foo<bar;'

# return文
assert 5  'return 5;'
assert 14 'return 2+3*4;'
assert 3  'a=3; return a;'
assert 7  'a=3; b=4; return a+b;'

# return後の文は実行されない
assert 5  'return 5; return 10;'
assert 3  'a=3; return a; a=100; a;'

# if文
assert 1 'if (1) return 1; return 0;'
assert 0 'if (0) return 1; return 0;'
assert 2 'if (1) return 2; else return 3;'
assert 3 'if (0) return 2; else return 3;'
assert 5 'a=5; if (a) return a; return 0;'
assert 2 'a=2; if (a==1) return 1; else if (a==2) return 2; else return 3;'

# while文
assert 5 'i=0; while(i<5) i=i+1; return i;'
assert 0 'i=0; while(i<0) i=i+1; return i;'

# for文
assert 5 'for(i=0; i<5; i=i+1) i=i; return i;'
assert 10 'sum=0; for(i=0; i<5; i=i+1) sum=sum+i; return sum;'
assert 5 'i=3; for(; i<5; i=i+1) i=i; return i;'

# {}ブロック
assert 3  '{ a=3; } return a;'
assert 3  '{ a=1; b=2; } return a+b;'
assert 2  'if (1) { a=1; a=a+1; } return a;'
assert 5  'if (0) { a=1; } else { a=5; } return a;'
assert 3  'i=0; while(i<3) { i=i+1; } return i;'
assert 10 'sum=0; for(i=1; i<=4; i=i+1) { sum=sum+i; } return sum;'
assert 3  '{ a=1; { b=2; } } return a+b;'

# 引数なし関数呼び出し（戻り値の検証）
assert 3 'return retthree();'
assert 5 'return retfive();'
assert 8 'return retthree() + retfive();'
assert 3 'a=retthree(); return a;'
assert 1 'if (retthree()==3) return 1; return 0;'

# 引数なし関数呼び出し（実際に呼ばれたかstdoutで確認）
assert_out "OK" 'printok();'
assert_out "OK" 'if (1) printok();'
assert_out "OK" 'i=0; while(i<1) { printok(); i=i+1; }'

# 引数あり関数呼び出し（戻り値の検証）
assert 5  'return add(2, 3);'
assert 6  'return mul(2, 3);'
assert 10 'return add(3, 7);'
assert 6  'return addthree(1, 2, 3);'
assert 5  'a=2; b=3; return add(a, b);'
assert 7  'return add(retthree(), retfive()-1);'

# 引数あり関数呼び出し（実際に呼ばれたかstdoutで確認）
assert_out "5"  'printsum(2, 3);'
assert_out "10" 'a=3; b=7; printsum(a, b);'
assert_out "5"  'printsum(retthree(), retfive()-3);'

echo OK