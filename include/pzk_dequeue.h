#ifndef PZK_DEQUEUE_H_
#define PZK_DEQUEUE_H_
#include <stdlib.h>
#include <pthread.h>

struct pzk_dequeue_node {
    struct pzk_dequeue_node* prev;
    struct pzk_dequeue_node* next;
    void*                    value;
};
typedef struct pzk_dequeue_node pzk_dequeue_node_t;

typedef struct {
    pzk_dequeue_node_t* first;
    pzk_dequeue_node_t* last;
    size_t              size;
    pthread_mutex_t*    mutex;
} pzk_dequeue_t;

pzk_dequeue_t* new_pzk_dequeue();
void destroy_pzk_dequeue(pzk_dequeue_t*);

int pzk_dequeue_push(pzk_dequeue_t*, void*);
void* pzk_dequeue_pop(pzk_dequeue_t*);

int pzk_dequeue_unshift(pzk_dequeue_t*, void*);
void* pzk_dequeue_shift(pzk_dequeue_t*);

#endif // ifndef PZK_DEQUEUE_H_
