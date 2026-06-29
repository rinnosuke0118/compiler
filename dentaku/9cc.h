#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdarg.h>
#include <stdbool.h>
#include <string.h>

//トークンの種類
typedef enum {
    TK_RESERVED, //記号
    TK_IDENT,    // 識別子
    TK_RETURN,   // return
    TK_IF,   //if
    TK_ELSE,   //else
    TK_FOR,   //for
    TK_WHILE,   //while
    TK_NUM,      // 整数トークン
    TK_EOF,  //入力の終わりを表すトークン
} TokenKind;

typedef struct Token Token;

//トークン型
struct Token {
    TokenKind kind; // トークンの型
    Token *next; // 次の入力トークン
    int val; // kindがTK_NUMの場合、その数値
    char *str; // トークン文字列
    int len; // トークンの長さ
};

extern Token *token;
extern char *user_input;

void error(char *fmt, ...);
void error_at(char *loc, char *fmt, ...);
bool consume(char *op);
Token *consume_ident();
bool consume_return();
bool consume_if();
bool consume_else();
bool consume_for();
bool consume_while();
void expect(char *op);
int expect_number();
bool at_eof();
Token *new_token(TokenKind kind, Token *cur, char *str, int len);
int startswith(char *p, char *q);
int is_alnum(char c);
Token *tokenize(char *p);

typedef struct LVar LVar;

// ローカル変数の型
struct LVar {
    LVar *next; // 次の変数かNULL
    char *name; // 変数の名前
    int len;    // 名前の長さ
    int offset; // RBPからのオフセット
};

extern LVar *locals;

// 抽象構文木のノードの種類
typedef enum {
    ND_ADD, // +
    ND_SUB, // -
    ND_MUL, // *
    ND_DIV, // /
    ND_ASSIGN, // =
    ND_LVAR,   // ローカル変数
    ND_NUM, // 整数
    ND_EQ,  // ==
    ND_NE,  // !=
    ND_LT,  // <
    ND_LE,  // <=
    ND_RETURN,  // return
    ND_IF,  // if
    ND_FOR,  // for
    ND_WHILE,  // while
    ND_BLOCK  // {}
} NodeKind;

typedef struct Node Node;

// 抽象構文木のノードの型
struct Node {
    NodeKind kind;
    Node *lhs;
    Node *rhs;
    // "if" ( cond ) then "else" els
    // "for" ( init; cond; inc ) body
    // "while" ( cond ) body
    Node *cond;
    Node *init;
    Node *inc;
    int val;
    int offset;    // kindがND_LVARの場合のみ使う
    // ND_BLOCK用: ブロック内の文の動的配列
    Node **body;
    int body_len;
};

Node *new_node(NodeKind kind, Node *lhs, Node *rhs);
Node *new_node_num(int val);
Node *expr();
Node *equality();
Node *relational();
Node *add();
Node *mul();
Node *unary();
Node *primary();

extern Node *code[];
void program();

void gen_lval(Node *node);
void gen(Node *node);