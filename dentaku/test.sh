#!/bin/bash
assert(){
    expected="$1"
    input="$2"

    ./9cc "$input" > tmp.s
    cc -o tmp tmp.s
    ./tmp
    actual="$?"

    if [ "$actual" = "$expected" ]; then
        echo "$input => $actual"
    else
        echo "$input => $expected expected, but got $actual"
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

echo OK