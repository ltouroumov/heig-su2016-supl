#include <iostream>
#include "parser.hpp"

using namespace std;

int main(int argc, char *argv[])
{
  extern FILE *yyin;
  extern int yydebug;
  argv++; argc--;
  extern char *fn_pfx;

  while (argc > 0) {
    // prepare filename prefix (cut off extension)
    fn_pfx = strdup(argv[0]);
    char *dot = strrchr(fn_pfx, '.');
    if (dot != NULL) *dot = '\0';

    // open source file
    yyin = fopen(argv[0], "r");
    yydebug = 0;

    // parse
    yyparse();

    // next input
    free(fn_pfx);
    argv++; argc--;
  }

  return 0;
}