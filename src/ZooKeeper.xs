#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <string.h>

#include <pzk.h>
#include <pzk_dequeue.h>
#include <pzk_watcher.h>
#include <pzk_xs_utils.h>
#include <zookeeper/zookeeper.h>


MODULE = ZooKeeper PACKAGE = ZooKeeper 

BOOT:
{
    zoo_set_debug_level(0);
    zoo_set_log_stream(NULL);
}

static void
_xs_init(self, host, recv_timeout, watcher=NULL, clientid=NULL, flags=0)
        SV*               self
        const char*       host
        pzk_watcher_t*    watcher
        int               recv_timeout
        const clientid_t* clientid
        int               flags
    PPCODE:
        if (SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV) {
            watcher_fn cb = watcher ? pzk_watcher_cb : NULL;
            zhandle_t* handle = zookeeper_init(host, cb, recv_timeout, clientid, (void*) watcher, flags);
            pzk_t* pzk = new_pzk(handle);

            sv_magic(SvRV(self), Nullsv, PERL_MAGIC_ext, (const char*) pzk, 0);
        }

int
add_auth(pzk_t* pzk, char* scheme, char* credential=NULL, pzk_watcher_t* watcher=NULL)
    CODE:
        void_completion_t cb = watcher ? pzk_watcher_auth_cb : NULL;
        RETVAL = zoo_add_auth(pzk->handle, scheme, credential, strlen(credential), cb, (void*) watcher);
    OUTPUT:
        RETVAL

SV*
create(pzk_t* pzk, char* path, char* value, int buffer_len, struct ACL_vector* acl=NULL, int flags=0)
    CODE:
        char* buffer; Newxz(buffer, buffer_len + 1, char);
        size_t value_len = strlen(value);
        int rc = zoo_create(pzk->handle, path, value, value_len, acl, flags, buffer, buffer_len);
        RETVAL = newSVpv(buffer, 0);
        Safefree(buffer);
    OUTPUT:
        RETVAL

int
delete(pzk_t* pzk, char* path, int version=-1)
    CODE:
        RETVAL = zoo_delete(pzk->handle, path, version);
    OUTPUT:
        RETVAL

SV*
exists(pzk_t* pzk, char* path, pzk_watcher_t* watcher=NULL)
    CODE:
        int rc;
        struct Stat stat; Zero(&stat, 1, struct Stat);
        if (watcher) {
            rc = zoo_wexists(pzk->handle, path, pzk_watcher_cb, (void*) watcher, &stat);
        } else {
            rc = zoo_exists(pzk->handle, path, 0, &stat);
        }
        RETVAL = rc == ZOK ? stat_to_sv(aTHX_ &stat) : &PL_sv_undef;
    OUTPUT:
        RETVAL

void
get_children(pzk_t* pzk, char* path, pzk_watcher_t* watcher=NULL)
    PPCODE:
        int rc;
        struct String_vector strings; Zero(&strings, 1, struct String_vector);
        if (watcher) {
            rc = zoo_wget_children(pzk->handle, path, pzk_watcher_cb, (void*) watcher, &strings);
        } else {
            rc = zoo_get_children(pzk->handle, path, 0, &strings);
        }

        if (rc == ZOK) {
            int32_t size = strings.count;
            int i; for (i = 0; i < size; i++) {
                ST(i) = sv_2mortal(newSVpv(strings.data[i], 0));
            }
            XSRETURN(size);
        } else {
            XSRETURN_EMPTY;
        }

void
get(pzk_t* pzk, char* path, int buffer_len, pzk_watcher_t* watcher=NULL)
    PPCODE:
        int rc;
        char* buffer; Newxz(buffer, buffer_len + 1, char);
        struct Stat stat; Zero(&stat, 1, struct Stat);
        if (watcher) {
            rc = zoo_wget(pzk->handle, path, pzk_watcher_cb, watcher, buffer, &buffer_len, &stat);
        } else {
            rc = zoo_get(pzk->handle, path, 0, buffer, &buffer_len, &stat);
        }

        if (rc != ZOK) XSRETURN_EMPTY;

        ST(0) = newSVpv(buffer, 0);
        Safefree(buffer);
        if (GIMME_V == G_ARRAY) {
            ST(1) = sv_2mortal(stat_to_sv(aTHX_ &stat));
            XSRETURN(2);
        } else {
            XSRETURN(1);
        }

SV*
set(pzk_t* pzk, char* path, char* data, int version=-1)
    CODE:
        struct Stat stat; Zero(&stat, 1, struct Stat);
        int rc = zoo_set2(pzk->handle, path, data, strlen(data), version, &stat);
        RETVAL = rc == ZOK ? stat_to_sv(aTHX_ &stat) : &PL_sv_undef;

    OUTPUT:
        RETVAL

void
get_acl(pzk_t* pzk, char* path)
    PPCODE:
        struct Stat stat; Zero(&stat, 1, struct Stat);
        struct ACL_vector acl; Zero(&acl, 1, struct ACL_vector);
        int rc = zoo_get_acl(pzk->handle, path, &acl, &stat);

        ST(0) = sv_2mortal(acl_vector_to_sv(aTHX_ &acl));
        deallocate_ACL_vector(&acl);
        if (GIMME_V == G_ARRAY) {
            ST(1) = sv_2mortal(stat_to_sv(aTHX_ &stat));
            XSRETURN(2);
        } else {
            XSRETURN(1);
        }

int
set_acl(pzk_t* pzk, char* path, SV* acl_sv, int version=-1)
    CODE:
        struct ACL_vector* acl = sv_to_acl_vector(aTHX_ acl_sv);
        RETVAL = zoo_set_acl(pzk->handle, path, version, acl);
        Safefree(acl->data);
        Safefree(acl);
    OUTPUT:
        RETVAL

const clientid_t*
client_id(pzk_t* pzk)
    CODE:
        RETVAL = zoo_client_id(pzk->handle);
    OUTPUT:
        RETVAL


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

