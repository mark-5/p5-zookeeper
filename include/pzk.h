#ifndef PZK_H_
#define PZK_H_
#include <zookeeper/zookeeper.h>

typedef struct pzk {
    zhandle_t* handle;
    void (*destroy) (struct pzk*);
} pzk_t;

pzk_t* new_pzk(zhandle_t*);

#endif // ifndef PZK_H_
