#include <pzk_dequeue.h>

static pzk_dequeue_node_t* _new_pzk_dequeue_node(void* val) {
    pzk_dequeue_node_t* node = (pzk_dequeue_node_t*) calloc(1, sizeof(pzk_dequeue_node_t));
    node->value = val;
    return node;
}
static void _destroy_pzk_dequeue_node(pzk_dequeue_node_t* node) {
    if (node) free(node);
}

pzk_dequeue_t* new_pzk_dequeue() {
    pzk_dequeue_t* dq = (pzk_dequeue_t*) calloc(1, sizeof(pzk_dequeue_t));
    dq->mutex = (pthread_mutex_t*) calloc(1, sizeof(pthread_mutex_t));
    pthread_mutex_init(dq->mutex, NULL);
    return dq;
}

int pzk_dequeue_push(pzk_dequeue_t* dq, void* val) {
    pthread_mutex_lock(dq->mutex);
    pzk_dequeue_node_t* new = _new_pzk_dequeue_node(val);    

    pzk_dequeue_node_t* last = dq->last;
    if (last) {
        last->next = new;
        new->prev  = last;
        dq->last = new;
    } else {
        dq->first = dq->last = new;
    }
    dq->length++;

    pthread_mutex_unlock(dq->mutex);
    return 0;
}

int pzk_dequeue_unshift(pzk_dequeue_t* dq, void* val) {
    pthread_mutex_lock(dq->mutex);
    pzk_dequeue_node_t* new = _new_pzk_dequeue_node(val);    

    pzk_dequeue_node_t* first = dq->first;
    if (first) {
        first->prev = new;
        new->next   = first;
        dq->first = new;
    } else {
        dq->first = dq->last = new;
    }
    dq->length++;

    pthread_mutex_unlock(dq->mutex);
    return 0;
}

void* pzk_dequeue_pop(pzk_dequeue_t* dq) {
    pthread_mutex_lock(dq->mutex);
    pzk_dequeue_node_t* node;
    pzk_dequeue_node_t* last = dq->last;
    if (!last) {
        pthread_mutex_unlock(dq->mutex);
        return NULL;
    }

    pzk_dequeue_node_t* prev = last->prev;
    if (prev) {
        prev->next = NULL;
        dq->last = prev;
    } else {
        dq->first = dq->last = NULL;
    }

    void* value = last->value;
    _destroy_pzk_dequeue_node(last);

    dq->length--;
    pthread_mutex_unlock(dq->mutex);
    return value;
}

void* pzk_dequeue_shift(pzk_dequeue_t* dq) {
    pthread_mutex_lock(dq->mutex);
    pzk_dequeue_node_t* node;
    pzk_dequeue_node_t* first = dq->first;
    if (!first) {
        pthread_mutex_unlock(dq->mutex);
        return NULL;
    }

    pzk_dequeue_node_t* next = first->next;
    if (next) {
        next->prev  = NULL;
        dq->first = next;
    } else {
        dq->first = dq->last = NULL;
    }

    void* value = first->value;
    _destroy_pzk_dequeue_node(first);

    dq->length--;
    pthread_mutex_unlock(dq->mutex);
    return value;
}

void** pzk_dequeue_elements(pzk_dequeue_t* dq) {
    pthread_mutex_lock(dq->mutex);
    int i;
    pzk_dequeue_node_t* node;

    size_t length = dq->length;
    if (!length) {
        pthread_mutex_unlock(dq->mutex);
        return NULL;
    }
    
    void** elements = (void**) calloc(length + 1, sizeof(void*));
    for (i = 0, node = dq->first; i < length; i++, node = node->next) {
        elements[i] = node->value;
    }
    elements[length + 1] = NULL;

    pthread_mutex_unlock(dq->mutex);
    return elements;
}

void destroy_pzk_dequeue(pzk_dequeue_t* dq) {
    size_t length = dq->length;
    pzk_dequeue_node_t* node;

    if (length) {
        int i;
        for (i = 0, node = dq->first; i < length; i++) {
            pzk_dequeue_node_t* next = node->next;
            _destroy_pzk_dequeue_node(node);
            node = next;
        }
    }

    if (dq->mutex) {
        pthread_mutex_destroy(dq->mutex);
        free(dq->mutex);
    }

    free(dq);
}
