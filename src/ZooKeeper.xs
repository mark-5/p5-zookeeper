#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <pzk.h>
#include <pzk_dequeue.h>
#include <pzk_watcher.h>
#include <pzk_xs_utils.h>
#include <zookeeper/zookeeper.h>

#define ZOO_LOG_LEVEL_OFF 0


MODULE = ZooKeeper PACKAGE = ZooKeeper 

static void
_xs_init(self, host, fn=NULL, recv_timeout, clientid=NULL, context=NULL, flags=0)
        SV*         self
        const char* host
        watcher_fn  fn
        int         recv_timeout
        const       clientid_t* clientid
        void*       context
        int         flags
    PPCODE:
        if (SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV) {
            zhandle_t* handle = zookeeper_init(host, fn, recv_timeout, clientid, context, flags);
            pzk_t* pzk = new_pzk(handle);

            sv_magic(SvRV(self), Nullsv, PERL_MAGIC_ext, (const char*) pzk, 0);
        }


MODULE = ZooKeeper PACKAGE = ZooKeeper::Channel

static void
_xs_init(SV* self)
    PPCODE:
        if (SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV) {
            pzk_dequeue_t* channel = new_pzk_dequeue();
            sv_magic(SvRV(self), Nullsv, PERL_MAGIC_ext, (const char*) channel, 0);
        }

void
DESTROY(pzk_dequeue_t* channel)
    PPCODE:
        destroy_pzk_dequeue(channel);
        XSRETURN_YES;

void
send(pzk_dequeue_t* channel, ...)
    PPCODE:
        int i;
        for (i = 1; i < items; i++) {
            pzk_dequeue_push(channel, SvREFCNT_inc(ST(i)));
        }
        XSRETURN_YES;

SV*
recv(pzk_dequeue_t* channel)
    CODE:
        SV* element = (SV*) pzk_dequeue_shift(channel);
        if (!element) element = &PL_sv_undef;
        RETVAL = element;
    OUTPUT:
        RETVAL


MODULE = ZooKeeper PACKAGE = ZooKeeper::Watcher

static void
_xs_init(SV* self, SV* cb)
    PPCODE:
        if (SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV) {
            pzk_watcher_t* watcher = new_pzk_watcher((void*) cb);
            sv_magic(SvRV(self), Nullsv, PERL_MAGIC_ext, (const char*) watcher, 0);
        }

void
DESTROY(pzk_watcher_t* watcher)
    PPCODE:
        destroy_pzk_watcher(watcher);
        XSRETURN_YES;


MODULE = ZooKeeper PACKAGE = ZooKeeper::ACL

static struct ACL_vector*
ZOO_OPEN_ACL_UNSAFE(...)
    PROTOTYPE:
    CODE:
        RETVAL = &ZOO_OPEN_ACL_UNSAFE;
    OUTPUT:
        RETVAL

static struct ACL_vector*
ZOO_READ_ACL_UNSAFE(...)
    PROTOTYPE:
    CODE:
        RETVAL = &ZOO_READ_ACL_UNSAFE;
    OUTPUT:
        RETVAL

static struct ACL_vector*
ZOO_CREATOR_ALL_ACL(...)
    PROTOTYPE:
    CODE:
        RETVAL = &ZOO_CREATOR_ALL_ACL;
    OUTPUT:
        RETVAL

