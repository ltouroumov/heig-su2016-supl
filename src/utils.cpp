#include <cstdlib>
#include <cstdio>

#include "utils.hpp"

VarDecl* new_vardecl(EType vtype, IDlist* vids) {
    VarDecl* vdecl = (VarDecl*)calloc(1, sizeof(VarDecl));
    vdecl->vtype = vtype;
    vdecl->vids = vids;
    return vdecl;
}

void delete_vardecl(VarDecl* vardecl) {
    delete_idlist(vardecl->vids);
    free(vardecl);
}