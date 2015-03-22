#include <pzk_watcher.h>
#include <stdlib.h>
#include <string.h>

pzk_watcher_t* new_pzk_watcher(void* arg) {
    pzk_watcher_t* watcher = (pzk_watcher_t*) calloc(1, sizeof(pzk_watcher_t));
    watcher->channel = new_pzk_dequeue();
    watcher->arg = arg;
    return watcher;
}

void pzk_watcher_cb(
    zhandle_t*  zh,
    int         type,
    int         state,
    const char* path,
    void*       watcherCtx
) {
    pzk_watcher_t* watcher     = (pzk_watcher_t*) watcherCtx;
    pzk_watcher_event_t* event = new_pzk_watcher_event(type, state, path, watcher->arg);
    pzk_dequeue_push(watcher->channel, (void*) event);
}

void pzk_watcher_auth_cb(int ret, const void* data) {
    pzk_watcher_t* watcher = (pzk_watcher_t*) data;
    pzk_watcher_event_t* event = new_pzk_watcher_event(-1, ret, NULL, watcher->arg);
    pzk_dequeue_push(watcher->channel, (void*) event);
}

void destroy_pzk_watcher(pzk_watcher_t* watcher) {
    if (watcher->channel) {
        destroy_pzk_dequeue(watcher->channel);
    }
    free(watcher);
}

pzk_watcher_event_t* new_pzk_watcher_event(int type, int state, const char* path, void* arg) {
    pzk_watcher_event_t* event = (pzk_watcher_event_t*) calloc(1, sizeof(pzk_watcher_event_t));
    event->type  = type;
    event->state = state;
    event->arg   = arg;

    char* path_copy = calloc(strlen(path) + 1, sizeof(char));
    strcpy(path_copy, path);
    event->path = path_copy;

    return event;
}

void destroy_pzk_watcher_event(pzk_watcher_event_t* event) {
    if (event->path) {
        free(event->path);
    }
    free(event);
}

