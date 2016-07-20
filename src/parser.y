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
}

%union {
  long int num;
  char*    str;
  IDlist*  idl;
  EType    typ;
}

%code {
  Stack   *stack = NULL;
  Symtab *symtab = NULL;
  CodeBlock *cb  = NULL;

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
%token tMathMul
%token tMathExp
%token tLogicOp
%token tCmpOp
%token tStr
%token tIdent
%token tNumber

%type <str> tMathAdd
%type <str> tMathMul
%type <str> tMathExp
%type <str> tLogicOp
%type <str> tCmpOp
%type <str> tStr
%type <str> tIdent
%type <num> tNumber
%type <idl> idList
%type <typ> type

%%

program:
    { stack = init_stack(NULL); symtab = init_symtab(stack, NULL); }
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
    varDecl tTerm
    | funDecl
    ;

varDecl:
    type idList
    ;

varDecl_opt:
    %empty
    | varDecl
    ;

idList:
    tIdent { $$ = (IDlist*)calloc(1, sizeof(IDlist)); $$->id = $tIdent; }
    | idList tSep tIdent { $$ = (IDlist*)calloc(1, sizeof(IDlist)); $$->id = $tIdent; $$->next = $1; }
    ;

funDecl:
    type tIdent tLpar varDecl_opt tRpar
    stmtBlock
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
    ;

cond:
    tIf tLpar expression tRpar stmtBlock cond_else
    ;

cond_else:
    %empty
    | tElse stmtBlock
    ;

while:
    tWhile tLpar expression tRpar
    stmtBlock
    ;

call:
    tIdent tLpar call_args tRpar
    ;

call_args:
    %empty
    | expression
    | call_args tSep expression
    ;

return:
    tReturn expression_opt tTerm
    ;

read:
    tRead tIdent tTerm
    ;

write:
    tWrite tIdent tTerm
    ;

print:
    tPrint tStr tTerm
    ;

expression:
    tNumber
    | tIdent
    | expression tMathAdd expression
    | expression tMathMul expression
    | expression tMathExp expression
    | expression tLogicOp expression
    | expression tCmpOp expression
    | tLpar expression tRpar
    | call
    ;

expression_opt:
    %empty
    | expression
    ;

%%

int yyerror(const char *msg)
{
  printf("Parse error at %d:%d: %s\n", yylloc.first_line, yylloc.first_column, msg);
  return 0;
}