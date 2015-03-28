#include <pzk_dispatcher.h>
#include <stdlib.h>
#include <string.h>

void pzk_dispatcher_cb(
    zhandle_t*  zh,
    int         type,
    int         state,
    const char* path,
    void*       _watcher
) {
    pzk_watcher_t* watcher = (pzk_watcher_t*) _watcher;
    pzk_dispatcher_t* dispatcher = watcher->dispatcher;

    pzk_event_t* event = new_pzk_event(type, state, path, watcher->event_ctx);
    pzk_dequeue_push(dispatcher->channel, (void*) event);

    dispatcher->notify(dispatcher);
}

void pzk_dispatcher_auth_cb(int ret, const void* _watcher) {
    pzk_watcher_t* watcher = (pzk_watcher_t*) _watcher;
    pzk_dispatcher_t* dispatcher = watcher->dispatcher;

    pzk_event_t* event = new_pzk_event(-1, ret, NULL, watcher->event_ctx);
    pzk_dequeue_push(dispatcher->channel, (void*) event);

    dispatcher->notify(dispatcher);
}

pzk_event_t* new_pzk_event(int type, int state, const char* path, void* arg) {
    pzk_event_t* event = (pzk_event_t*) calloc(1, sizeof(pzk_event_t));
    event->type  = type;
    event->state = state;
    event->arg   = arg;

    if (path) {
        char* path_copy = calloc(strlen(path) + 1, sizeof(char));
        strcpy(path_copy, path);
        event->path = path_copy;
    } else {
        event->path = NULL;
    }

    return event;
}

void destroy_pzk_event(pzk_event_t* event) {
    if (event->path) {
        free(event->path);
    }
    free(event);
}

