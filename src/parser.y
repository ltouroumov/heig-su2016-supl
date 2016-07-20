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

%type <str> tStr
%type <str> tIdent
%type <num> tNumber
%type <idl> idList varDecl varDecl_opt
%type <typ> type

%left tMathAdd tMathSub
%left tMathMul tMathDiv tMathMod
%left tMathExp

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
    tIf tLpar condition tRpar stmtBlock cond_else
    ;

cond_else:
    %empty
    | tElse stmtBlock
    ;

while:
    tWhile tLpar condition tRpar
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
    expression tCmpEq expression
    | expression tCmpLe expression
    | expression tCmpLt expression
    ;

%%

int yyerror(const char *msg)
{
  printf("Parse error at %d:%d: %s\n", yylloc.first_line, yylloc.first_column, msg);
  return 0;
}