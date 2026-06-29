# 9cc — 自作Cコンパイラ

整数演算・変数・制御構文を x86-64 アセンブリへコンパイルする学習用コンパイラです。

[低レイヤを知りたい人のためのCコンパイラ作成入門](https://www.sigbus.info/compilerbook) を参考に実装しています。

## ビルド

```bash
cd dentaku
make
```

## テスト

```bash
make test
```

## 使い方

```bash
./9cc 'プログラム' > tmp.s
cc -o tmp tmp.s
./tmp; echo $?
```

## 対応機能

### 演算子

| 種類 | 記号 |
|------|------|
| 四則演算 | `+` `-` `*` `/` |
| 比較 | `==` `!=` `<` `<=` `>` `>=` |
| 代入 | `=` |
| 単項 | `+` `-` |

### 変数

- 小文字アルファベットのみで構成されたローカル変数（`a`〜`z`、`foo`、`myvar` など）
- 変数宣言不要。初回代入で自動的に確保される
- 変数名に数字・アンダースコアは使用不可

### 文

| 構文 | 例 |
|------|----|
| 式文 | `a = 3;` |
| return文 | `return a + 1;` |
| if文 | `if (a) return 1; else return 0;` |
| while文 | `while (i < 10) i = i + 1;` |
| for文 | `for (i = 0; i < 10; i = i + 1) s = s + i;` |
| ブロック文 | `{ a = 1; b = 2; }` |

- `if` / `while` / `for` の本体にはブロック `{ }` も使用可能
- `for` の init / cond / inc はすべて省略可能
- `else if` による多分岐も可能

### 制約

- 関数定義・関数呼び出し不可
- 型なし（整数のみ）
- 配列・ポインタ不可

## ファイル構成

```
dentaku/
├── 9cc.h       — 型定義・プロトタイプ宣言
├── tokenize.c  — トークナイザ
├── parse.c     — パーサ（AST構築）
├── codegen.c   — コード生成（x86-64 アセンブリ出力）
├── main.c      — エントリポイント
├── Makefile
└── test.sh     — テストスクリプト
```

## アーキテクチャ

```
入力文字列
  │
  ▼ tokenize()
トークン列
  │
  ▼ program() / stmt() / expr() / ...
抽象構文木（AST）
  │
  ▼ gen()
x86-64 アセンブリ（Intel記法）
```

パーサは以下の生成規則を再帰下降で実装しています。

```
program    = stmt*
stmt       = expr ";"
           | "{" stmt* "}"
           | "if" "(" expr ")" stmt ("else" stmt)?
           | "while" "(" expr ")" stmt
           | "for" "(" expr? ";" expr? ";" expr? ")" stmt
           | "return" expr ";"
expr       = assign
assign     = equality ("=" assign)?
equality   = relational ("==" relational | "!=" relational)*
relational = add ("<" add | "<=" add | ">" add | ">=" add)*
add        = mul ("+" mul | "-" mul)*
mul        = unary ("*" unary | "/" unary)*
unary      = ("+" | "-")? primary
primary    = num | ident | "(" expr ")"
```

コード生成はスタックマシン方式で、すべての式はスタックに値を1つ積んで返します。
