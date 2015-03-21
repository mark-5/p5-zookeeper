#include <pzk.h>
#include <stdlib.h>

pzk_t* new_pzk() {
    return (pzk_t*) calloc(1, sizeof(pzk_t));
}

void destroy_pzk(pzk_t* pzk) {
    free(pzk);
}

