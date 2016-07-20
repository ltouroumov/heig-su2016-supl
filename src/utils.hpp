#ifndef __UTILS__
#define __UTILS__

#include "supllib.hpp"

typedef struct __vardecl {
    EType vtype;
    IDlist* vids;
} VarDecl;

VarDecl* new_vardecl(EType vtype, IDlist* vids);
void delete_vardecl(VarDecl* vardecl);

#endif