#include <pzk.h>
#include <stdlib.h>

pzk_t* new_pzk(zhandle_t* handle) {
    pzk_t* pzk  = (pzk_t*) calloc(1, sizeof(pzk_t));
    pzk->handle = handle;
    return pzk;
}

void destroy_pzk(pzk_t* pzk) {
    free(pzk);
}

