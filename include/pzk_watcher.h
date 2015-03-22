#ifndef PZK_WATCHER_H_
#define PZK_WATCHER_H_
#include "pzk_dequeue.h"
#include <zookeeper/zookeeper.h>

typedef struct {
    pzk_dequeue_t* channel;
    void*          arg;
} pzk_watcher_t;

typedef struct {
    int   type;
    int   state;
    char* path;
    void* arg;
} pzk_watcher_event_t;

void pzk_watcher_cb(
    zhandle_t*  zh,
    int         type,
    int         state,
    const char* path,
    void*       watcherCtx
);

pzk_watcher_t* new_pzk_watcher(void*);
void destroy_pzk_watcher(pzk_watcher_t*);

pzk_watcher_event_t* new_pzk_watcher_event(int type, int state, const char* path, void* arg);
void destroy_pzk_watcher_event(pzk_watcher_event_t*);

#endif // ifndef PZK_WATCHER_H_
