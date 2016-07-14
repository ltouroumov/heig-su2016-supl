#include <iostream>
#include "lexer.hpp"

using namespace std;

int main(int argc, char* argv[]) {
    yyin = stdin;
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    }
    yylex();
    fclose(yyin);
    return 0;
}