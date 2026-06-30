#include "9cc.h"

static int label_count = 0;

void gen_lval(Node *node) {
  if (node->kind == ND_LVAR) {
      printf("  mov rax, rbp\n");
      printf("  sub rax, %d\n", node->offset);
      printf("  push rax\n");
  } else if (node->kind == ND_DEREF) {
      gen(node->lhs);   // ポインタ値（書き込み先アドレス）をスタックに積む
  } else {
      error("代入の左辺値が変数ではありません");
  }
}

// 抽象構文木をアセンブリコードに変換する
void gen(Node *node){
    switch (node->kind) {
        case ND_NUM:
            printf("  push %d\n", node->val);
            return;
        case ND_LVAR:
            gen_lval(node);
            printf("  pop rax\n");
            printf("  mov rax, [rax]\n");
            printf("  push rax\n");
            return;
        case ND_ASSIGN:
            gen_lval(node->lhs);
            gen(node->rhs);

            printf("  pop rdi\n");
            printf("  pop rax\n");
            printf("  mov [rax], rdi\n");
            printf("  push rdi\n");
            return;
        case ND_RETURN:
            gen(node->lhs);
            printf("  pop rax\n");
            printf("  mov rsp, rbp\n");
            printf("  pop rbp\n");
            printf("  ret\n");
            return;
        case ND_IF: {
            int c = label_count++;
            gen(node->cond);
            printf("  pop rax\n");
            printf("  cmp rax, 0\n");
            printf("  je  .Lelse%d\n", c);
            gen(node->lhs);
            printf("  jmp  .Lend%d\n", c);
            printf(".Lelse%d:\n", c);
            if (node->rhs) {
                gen(node->rhs);
            } else {
                printf("  push 0\n");
            }
            printf(".Lend%d:\n", c);
            return;
        }
        case ND_WHILE: {
            int c = label_count++;
            printf(".Lbegin%d:\n", c);
            gen(node->cond);
            printf("  pop rax\n");
            printf("  cmp rax, 0\n");
            printf("  je  .Lend%d\n", c);
            gen(node->lhs);
            printf("  pop rax\n");
            printf("  jmp .Lbegin%d\n", c);
            printf(".Lend%d:\n", c);
            printf("  push 0\n");
            return;
        }
        case ND_FOR: {
            int c = label_count++;
            if(node->init){
                gen(node->init);
                printf("  pop rax\n");
            }
            printf(".Lbegin%d:\n", c);
            if(node->cond){
                gen(node->cond);
                printf("  pop rax\n");
                printf("  cmp rax, 0\n");
                printf("  je  .Lend%d\n", c);
            }
            gen(node->lhs);
            printf("  pop rax\n");
            if(node->inc){
                gen(node->inc);
                printf("  pop rax\n");
            }
            printf("  jmp .Lbegin%d\n", c);
            printf(".Lend%d:\n", c);
            printf("  push 0\n");
            return;
        }
        case ND_BLOCK: {
            for (int i = 0; i < node->body_len; i++) {
                gen(node->body[i]);
                printf("  pop rax\n");
            }
            printf("  push 0\n");
            return;
        }
        case ND_CALL: {
            // 全引数をスタックにpush
            for (int i = 0; i < node->args_len; i++) {
                gen(node->args[i]);
            }

            // 逆順にレジスタへpop
            static const char *regs[] = {"rdi", "rsi", "rdx", "rcx", "r8", "r9"};
            for (int i = node->args_len - 1; i >= 0; i--){
                printf("  pop %s\n", regs[i]);
            }

            // x86-64 ABI: call直前にrspが16バイト境界である必要がある
            // スタックマシンで途中に値が積まれていると8バイトずれる場合があるため補正する
            int c = label_count++;
            printf("  mov rax, rsp\n");
            printf("  and rax, 15\n");
            printf("  jnz .Lmisaligned%d\n", c);

            printf("  call %.*s\n", node->funcname_len, node->funcname);
            printf("  jmp .Lcallend%d\n", c);

            printf(".Lmisaligned%d:\n", c);
            printf("  sub rsp, 8\n");
            printf("  call %.*s\n", node->funcname_len, node->funcname);
            printf("  add rsp, 8\n");

            printf(".Lcallend%d:\n", c);
            printf("  push rax\n");
            return;
        }
        case ND_FUNCDEF: {
            static const char *regs[] = {"rdi", "rsi", "rdx", "rcx", "r8", "r9"};
            // ラベルとプロローグ
            printf(".global %.*s\n", node->funcname_len, node->funcname);
            printf("%.*s:\n", node->funcname_len, node->funcname);
            printf("  push rbp\n");
            printf("  mov rbp, rsp\n");
            printf("  sub rsp, %d\n", node->locals_size);
            // 引数レジスタをスタック上のローカル変数領域に書き出す
            for (int i = 0; i < node->params_len; i++) {
                printf("  mov [rbp-%d], %s\n", node->params[i]->offset, regs[i]);
            }
            // 関数本体
            gen(node->lhs);
            printf("  pop rax\n");
            // エピローグ（return文がない場合のフォールスルー用）
            printf("  mov rsp, rbp\n");
            printf("  pop rbp\n");
            printf("  ret\n");
            return;
        }
        case ND_ADDR: {
            gen_lval(node->lhs);
            return;
        }
        case ND_DEREF: {
            gen(node->lhs);
            printf("  pop rax\n");
            printf("  mov rax, [rax]\n");
            printf("  push rax\n");
            return;
        }
    }
    
    gen(node->lhs);
    gen(node->rhs);

    printf("  pop rdi\n");
    printf("  pop rax\n");

    switch(node->kind){
        case ND_ADD:
            printf("  add rax, rdi\n");
            break;
        case ND_SUB:
            printf("  sub rax, rdi\n");
            break;
        case ND_MUL:
            printf("  imul rax, rdi\n");
            break;
        case ND_DIV:
            printf("  cqo\n");
            printf("  idiv rdi\n");
            break;
        case ND_EQ:
            printf("  cmp rax, rdi\n");
            printf("  sete al\n");
            printf("  movzb rax, al\n");
            break;
        case ND_NE:
            printf("  cmp rax, rdi\n");
            printf("  setne al\n");
            printf("  movzb rax, al\n");
            break;
        case ND_LT:
            printf("  cmp rax, rdi\n");
            printf("  setl al\n");
            printf("  movzb rax, al\n");
            break;
        case ND_LE:
            printf("  cmp rax, rdi\n");
            printf("  setle al\n");
            printf("  movzb rax, al\n");
            break;
    }

    printf("  push rax\n");
}