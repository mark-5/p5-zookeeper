#ifndef PZK_H_
#define PZK_H_
#include <zookeeper/zookeeper.h>

typedef struct {
    zhandle_t* handle;
} pzk_t;

pzk_t* new_pzk(zhandle_t*);
void destroy_pzk(pzk_t*);

#endif // ifndef PZK_H_
