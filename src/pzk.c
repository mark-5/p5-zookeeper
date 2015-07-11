#include <pzk.h>
#include <stdlib.h>

static void destroy_pzk(pzk_t* pzk) {
    free(pzk);
}

pzk_t* new_pzk(zhandle_t* handle) {
    pzk_t* pzk   = (pzk_t*) calloc(1, sizeof(pzk_t));
    pzk->handle  = handle;
    pzk->destroy = destroy_pzk;
    return pzk;
}


