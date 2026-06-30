#include "9cc.h"

Node *new_node(NodeKind kind, Node *lhs, Node *rhs){
    Node *node = calloc(1, sizeof(Node));
    node->kind = kind;
    node->lhs = lhs;
    node->rhs = rhs;
    return node;
}

Node *new_node_num(int val){
    Node *node = calloc(1, sizeof(Node));
    node->kind = ND_NUM;
    node->val = val;
    return node;
}

// 変数を名前で検索する。見つからなかった場合はNULLを返す。
LVar *find_lvar(Token *tok) {
  for (LVar *var = locals; var; var = var->next)
    if (var->len == tok->len && !memcmp(tok->str, var->name, var->len))
      return var;
  return NULL;
}

// 関数を名前で検索する。見つからなかった場合はNULLを返す。
LFunc *find_lfunc(Token *tok) {
  for (LFunc *func = funcs; func; func = func->next)
    if (func->len == tok->len && !memcmp(tok->str, func->name, func->len))
      return func;
  return NULL;
}

LVar *locals;
LFunc *funcs;

Node *code[100];

Node *assign() {
  Node *node = equality();
  if (consume("="))
    node = new_node(ND_ASSIGN, node, assign());
  return node;
}

Node *expr() {
  return assign();
}

Node *stmt() {
  Node *node;

  if (consume("{")) {
    node = calloc(1, sizeof(Node));
    node->kind = ND_BLOCK;
    int cap = 8;
    node->body = malloc(sizeof(Node *) * cap);
    while (!consume("}")) {
      if (node->body_len == cap) {
        cap *= 2;
        node->body = realloc(node->body, sizeof(Node *) * cap);
      }
      node->body[node->body_len++] = stmt();
    }
    return node;
  }

  if (consume_if()) {
    node = calloc(1, sizeof(Node));
    node->kind = ND_IF;
    expect("(");
    node->cond = expr();
    expect(")");
    node->lhs = stmt();
    if (consume_else())
      node->rhs = stmt();
    return node;
  }

  if (consume_while()) {
    node = calloc(1, sizeof(Node));
    node->kind = ND_WHILE;
    expect("(");
    node->cond = expr();
    expect(")");
    node->lhs = stmt();
    return node;
  }

  if (consume_for()) {
    node = calloc(1, sizeof(Node));
    node->kind = ND_FOR;
    expect("(");
    if (!consume(";")) {
      node->init = expr();
      expect(";");
    }
    if (!consume(";")) {
      node->cond = expr();
      expect(";");
    }
    if (!consume(")")) {
      node->inc = expr();
      expect(")");
    }
    node->lhs = stmt();
    return node;
  }

  if (consume_return()) {
    node = calloc(1, sizeof(Node));
    node->kind = ND_RETURN;
    node->lhs = expr();
  } else {
    node = expr();
  }

  expect(";");
  return node;
}

Node *funcdef() {
    // localsをリセット（関数ごとにローカル変数を独立させる）
    locals = NULL;

    Token *tok = consume_ident();
    expect("(");

    Node *node = calloc(1, sizeof(Node));
    node->kind = ND_FUNCDEF;
    node->funcname = tok->str;
    node->funcname_len = tok->len;
    if (!find_lfunc(tok)) {
        LFunc *lfunc = calloc(1, sizeof(LFunc));
        lfunc->next = funcs;
        lfunc->name = tok->str;
        lfunc->len = tok->len;
        funcs = lfunc;
    } else {
        error("関数の2重定義です");
    }

    if(!consume(")")) {
        int cap = 6;
        node->params = malloc(sizeof(LVar *) * cap);
        do {
            if (node->params_len >= 6){
                error("引数は6個以下にしてください");
            }
            
            Token *ptok = consume_ident();
            LVar *lvar = calloc(1, sizeof(LVar));
            lvar->next = locals;
            lvar->name = ptok->str;
            lvar->len = ptok->len;
            lvar->offset = locals ? locals->offset + 8 : 8;
            locals = lvar;
            node->params[node->params_len++] = lvar;
        } while (consume(","));
        expect(")");
    }

    node->lhs = stmt();

    int sz = locals ? locals->offset : 0;
    node->locals_size = (sz + 15) & ~15;
    return node;
}

void program() {
  int i = 0;
  while (!at_eof()){
    code[i++] = funcdef();
  } 
  code[i] = NULL;
}

Node *equality() {
    Node *node = relational();

    for(;;){
        if(consume("==")){
            node = new_node(ND_EQ, node, relational());
        }else if(consume("!=")){
            node = new_node(ND_NE, node, relational());
        }else{
            return node;
        }
    }
}

Node *relational() {
    Node *node = add();

    for(;;){
        if(consume("<")){
            node = new_node(ND_LT, node, add());
        }else if(consume("<=")){
            node = new_node(ND_LE, node, add());
        }else if(consume(">")){
            node = new_node(ND_LT, add(), node);
        }else if(consume(">=")){
            node = new_node(ND_LE, add(), node);
        }else{
            return node;
        }
    }
}

Node *add() {
    Node *node = mul();

    for(;;){
        if(consume("+")){
            node = new_node(ND_ADD, node, mul());
        }else if(consume("-")){
            node = new_node(ND_SUB, node, mul());
        }else{
            return node;
        }
    }
}

Node *mul() {
    Node *node = unary();

    for(;;){
        if(consume("*")){
            node = new_node(ND_MUL, node, unary());
        }else if(consume("/")){
            node = new_node(ND_DIV, node, unary());
        }else{
            return node;
        }
    }
}

Node *unary(){
    if(consume("+")){
        return primary();
    }
    if(consume("-")){
        return new_node(ND_SUB, new_node_num(0), primary());
    }
    return primary();
}

Node *primary(){
    if(consume("(")){
        Node *node = expr();
        expect(")");
        return node;
    }

    Token *tok = consume_ident();
    if (tok) {
        Node *node = calloc(1, sizeof(Node));
        if (consume("(")) {
            node->kind = ND_CALL;
            node->funcname = tok->str;
            node->funcname_len = tok->len;
            if (!find_lfunc(tok)) {
                LFunc *lfunc = calloc(1, sizeof(LFunc));
                lfunc->next = funcs;
                lfunc->name = tok->str;
                lfunc->len = tok->len;
                funcs = lfunc;
            }

            if(!consume(")")) {
                int cap = 6;
                node->args = malloc(sizeof(Node *) * cap);
                do {
                    if (node->args_len >= 6)
                        error("引数は6個以下にしてください");
                    node->args[node->args_len++] = expr();
                } while (consume(","));
                expect(")");
            }
        } else {
            node->kind = ND_LVAR;

            LVar *lvar = find_lvar(tok);
            if (lvar) {
                node->offset = lvar->offset;
            } else {
                lvar = calloc(1, sizeof(LVar));
                lvar->next = locals;
                lvar->name = tok->str;
                lvar->len = tok->len;
                lvar->offset = locals ? locals->offset + 8 : 8;
                node->offset = lvar->offset;
                locals = lvar;
            }
        }
        return node;
    }

    return new_node_num(expect_number());
}