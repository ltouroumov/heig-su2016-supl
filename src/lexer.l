%option noyywrap

IDENT [a-zA-Z_][a-zA-Z0-9_]*

%%

[ \n\t] {;}

int     { printf("(int)\n"); }
void    { printf("(void)\n"); }

if      { printf("(if)\n"); }
while   { printf("(while)\n"); }

print   { printf("(print)\n"); }
read    { printf("(read)\n"); }
write   { printf("(write)\n"); }

,       { printf("(sep)\n"); }
;       { printf("(term)\n"); }
"{"     { printf("(lbr)\n"); }
"}"     { printf("(rbr)\n"); }
"("     { printf("(lpar)\n"); }
")"     { printf("(rpar)\n"); }

"="                    { printf("(assign)\n"); }
"-"|"+"                { printf("(op, %s)\n", yytext); }
"&&"|"||"              { printf("(lop, %s)\n", yytext); }
"=="|"<="|">="|"<"|">" { printf("(cmp, %s)\n", yytext); }

\".+\"  { printf("(str, %s)\n", yytext); }

{IDENT} { printf("(ident, %s)\n", yytext); }
[0-9]   { printf("(int, %s)\n", yytext); }

.       { printf("(??, %s)\n", yytext); }

%%