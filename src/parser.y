%locations

%code top{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lexer.hpp"
#define YYDEBUG 1

extern char *yytext;
int yyerror(const char *msg);
}

%code requires {
    #include "supllib.hpp"
    #include "utils.hpp"
}

%union {
  long int num;
  char*    str;
  IDlist*  idl;
  EType    typ;
  EOpcode  opc;
  BPrecord* bpr;
}

%code {
  Stack   *stack = NULL;
  Symtab *symtab = NULL;
  CodeBlock *cb  = NULL;
  Funclist* func = NULL;

  char *fn_pfx   = NULL;
  EType rettype  = tVoid;
}

%start program

%token tIf
%token tElse
%token tWhile
%token tReturn
%token tIntType
%token tVoidType
%token tPrint
%token tRead
%token tWrite
%token tSep
%token tTerm
%token tLbr
%token tRbr
%token tLpar
%token tRpar
%token tAssign
%token tMathAdd
%token tMathSub
%token tMathMul
%token tMathDiv
%token tMathMod
%token tMathExp
%token tCmpEq
%token tCmpLe
%token tCmpLt
%token tStr
%token tIdent
%token tNumber
%token tQuote
%token tChr

%type <str> tStr
%type <str> tIdent
%type <num> tNumber tChr
%type <idl> idList varDecl varDecl_opt
%type <typ> type
%type <opc> condition
%type <bpr> tIf tWhile

%left tMathAdd tMathSub
%left tMathMul tMathDiv tMathMod
%left tMathExp

%%

program:
    { stack = init_stack(NULL); symtab = init_symtab(stack, NULL); func = NULL; }
    declList
    {
        cb = init_codeblock(""); 
        stack = init_stack(stack); symtab = init_symtab(stack, symtab);
        rettype = tVoid;
    }
    stmtBlock
    { 
        add_op(cb, opHalt, NULL);
        dump_codeblock(cb); save_codeblock(cb, fn_pfx);
        Stack *pstck = stack; stack = stack->uplink; delete_stack(pstck);
        Symtab *pst = symtab; symtab = symtab->parent; delete_symtab(pst);
    }
    ;

declList:
    %empty
    | decl
    | declList decl
    ;

decl:
    varDecl tTerm { delete_idlist($varDecl); }
    | funDecl
    ;

varDecl:
    type idList
    { 
        IDlist *l = $idList;
        while (l) { 
            if (insert_symbol(symtab, l->id, $type) == NULL) {
                char *error = NULL;
                asprintf(&error, "Duplicated identifier '%s'.", l->id);
                yyerror(error);
                free(error);
                YYABORT;
            } else {
                printf("declared %s\n", l->id);
            }
            l = l->next;
        }
        $$ = $idList;
    }
    ;

varDecl_opt:
    %empty { $$ = NULL; }
    | varDecl
    ;

idList:
    tIdent { $$ = (IDlist*)calloc(1, sizeof(IDlist)); $$->id = $tIdent; }
    | idList tSep tIdent { $$ = (IDlist*)calloc(1, sizeof(IDlist)); $$->id = $tIdent; $$->next = $1; }
    ;

funDecl:
    type tIdent
    {
        cb = init_codeblock($tIdent); 
        stack = init_stack(stack); symtab = init_symtab(stack, symtab);
        rettype = $type;
    } 
    tLpar varDecl_opt tRpar
    {
        Funclist* ff = (Funclist*)calloc(1, sizeof(Funclist));
        ff->id = strdup($tIdent);
        ff->rettype = $type;
        int cnt =0;
        IDlist* l = $varDecl_opt;
        while(l){cnt++; l = l->next;}
        ff->narg = cnt;
        ff->next = func;
        func = ff;

        if ($varDecl_opt != NULL) {
            delete_idlist($varDecl_opt);
        }
    }
    stmtBlock
    {
        if (rettype != tVoid) {
            add_op(cb, opPush, 0);
        }
        add_op(cb, opReturn, NULL);
        dump_codeblock(cb); save_codeblock(cb, fn_pfx);
        Stack *pstck = stack; stack = stack->uplink; delete_stack(pstck);
        Symtab *pst = symtab; symtab = symtab->parent; delete_symtab(pst);
    }
    ;

type:
    tIntType { $$ = tInteger; }
    | tVoidType { $$ = tVoid; }
    ;

stmtBlock:
    tLbr stmt_list tRbr
    ;

stmt:
    varDecl tTerm
    | assign
    | cond
    | while
    | call tTerm
    | return
    | read
    | write
    | print
    ;

stmt_list:
    %empty
    | stmt
    | stmt_list stmt
    ;

assign:
    tIdent tAssign expression tTerm
    {
        Symbol* id = find_symbol(symtab, $tIdent, sGlobal);
        add_op(cb, opStore, id);
    }
    ;

cond:
    tIf tLpar condition tRpar
    {
        $tIf = (BPrecord*)calloc(1, sizeof(BPrecord));

        Operation* trueJmp = add_op(cb, $condition, NULL);
        Operation* falseJmp = add_op(cb, opJump, NULL);

        $tIf->ttrue = add_backpatch($tIf->ttrue, trueJmp);
        $tIf->tfalse = add_backpatch($tIf->tfalse, falseJmp);

        pending_backpatch(cb, $tIf->ttrue);
    }
    stmtBlock
    {
        Operation* endJmp = add_op(cb, opJump, NULL);
        $tIf->end = add_backpatch($tIf->end, endJmp);

        pending_backpatch(cb, $tIf->tfalse);
    }
    condElse
    {
        pending_backpatch(cb, $tIf->end);
    }
    ;

condElse:
    %empty
    | tElse stmtBlock
    ;

while:
    tWhile
    {
        $tWhile = (BPrecord*)calloc(1, sizeof(BPrecord));

        $tWhile->pos = cb->nops;
    }
    tLpar condition tRpar
    {
        Operation* trueJmp = add_op(cb, $condition, NULL);
        Operation* falseJmp = add_op(cb, opJump, NULL);

        $tWhile->ttrue = add_backpatch($tWhile->ttrue, trueJmp);
        $tWhile->tfalse = add_backpatch($tWhile->tfalse, falseJmp);

        pending_backpatch(cb, $tWhile->ttrue);
    }
    stmtBlock
    {
        Operation* start = get_op(cb, $tWhile->pos);
        Operation* backJmp = add_op(cb, opJump, start);
        pending_backpatch(cb, $tWhile->tfalse);
    }
    ;

call:
    tIdent tLpar call_args tRpar
    {
        Funclist * fn = find_func(func, $tIdent);
        if (fn ==NULL){            
            yyerror("function does not exist!");
            YYABORT;
        }
        else {
            add_op(cb, opCall, $tIdent);
        }
    }
    ;

call_args:
    %empty
    | expression
    | call_args tSep expression
    ;

return:
    tReturn tTerm
    {
        if (rettype == tVoid) {
            add_op(cb, opReturn, NULL);
        } else {
            yyerror("Non void functions must return a value");
            YYABORT;
        }
    }
    | tReturn expression tTerm
    {
        if (rettype != tVoid) {
            add_op(cb, opReturn, NULL);
        } else {
            yyerror("Non void functions must return a value");
            YYABORT;
        }
    }
    ;

read:
    tRead tIdent tTerm
    {
        Symbol* id = find_symbol(symtab, $tIdent, sLocal);
        add_op(cb, opRead, id);
    }
    ;

write:
    tWrite expression tTerm
    {
        add_op(cb, opWrite, NULL);
    }
    ;

print:
    tPrint tStr tTerm
    {
        add_op(cb, opPrint, $tStr);
    }
    ;

expression:
    tNumber
    {
        add_op(cb, opPush, (void*)$tNumber);
    }
    | tIdent
    { 
        Symbol* id = find_symbol(symtab, $tIdent, sGlobal);
        add_op(cb, opLoad, id);
    }
    | expression tMathAdd expression { add_op(cb, opAdd, NULL); }
    | expression tMathSub expression { add_op(cb, opSub, NULL); }
    | expression tMathMul expression { add_op(cb, opMul, NULL); }
    | expression tMathDiv expression { add_op(cb, opDiv, NULL); }
    | expression tMathMod expression { add_op(cb, opMod, NULL); }
    | expression tMathExp expression { add_op(cb, opPow, NULL); }
    | tLpar expression tRpar
    | call
    ;

expression_opt:
    %empty
    | expression
    ;

condition:
    expression tCmpEq expression { $$ = opJeq; }
    | expression tCmpLe expression { $$ = opJle; }
    | expression tCmpLt expression { $$ = opJlt; }
    ;

%%

int yyerror(const char *msg)
{
  printf("Parse error at %d:%d: %s\n", yylloc.first_line, yylloc.first_column, msg);
  return 0;
}