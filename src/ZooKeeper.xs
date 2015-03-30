#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <string.h>

#include <pzk.h>
#include <pzk_dequeue.h>
#include <pzk_pipe_dispatcher.h>
#include <pzk_interrupt_dispatcher.h>
#include <pzk_xs_utils.h>
#include <zookeeper/zookeeper.h>


MODULE = ZooKeeper PACKAGE = ZooKeeper 

BOOT:
{
    zoo_set_debug_level(0);
    zoo_set_log_stream(NULL);
}

void
_xs_init(self, hosts, recv_timeout, watcher=NULL, clientid=NULL, flags=0)
        SV*               self
        const char*       hosts
        pzk_watcher_t*    watcher
        int               recv_timeout
        const clientid_t* clientid
        int               flags
    PPCODE:
        if (SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV) {
            watcher_fn cb = watcher ? pzk_dispatcher_cb : NULL;
            zhandle_t* handle = zookeeper_init(hosts, cb, recv_timeout, clientid, (void*) watcher, flags);
            if (!handle) throw_zerror(aTHX_ errno, "Error initializing ZooKeeper handle for '%s': %s", hosts, strerror(errno));

            pzk_t* pzk = new_pzk(handle);
            sv_magic(SvRV(self), Nullsv, PERL_MAGIC_ext, (const char*) pzk, 0);
        }

void
DESTROY(pzk_t* pzk)
    PPCODE:
        if (pzk) {
            if (pzk->handle) zookeeper_close(pzk->handle);
            destroy_pzk(pzk);
        }

int
state(pzk_t* pzk)
    CODE:
        if (!pzk) Perl_croak(aTHX_ "handle has not yet been initialized by ZooKeeper");
        RETVAL = zoo_state(pzk->handle);
    OUTPUT:
        RETVAL

void
add_auth(pzk_t* pzk, char* scheme, char* credential=NULL, pzk_watcher_t* watcher=NULL)
    PPCODE:
        if (!pzk) Perl_croak(aTHX_ "handle has not yet been initialized by ZooKeeper");

        void_completion_t cb = watcher ? pzk_dispatcher_auth_cb : NULL;
        int rc = zoo_add_auth(pzk->handle, scheme, credential, strlen(credential), cb, (void*) watcher);
        if (rc != ZOK) throw_zerror(aTHX_ rc, "Error trying to authenticate: %s", zerror(rc));

SV*
create(pzk_t* pzk, char* path, char* value, int buffer_len, struct ACL_vector* acl=NULL, int flags=0)
    CODE:
        if (!pzk) Perl_croak(aTHX_ "handle has not yet been initialized by ZooKeeper");

        char* buffer; Newxz(buffer, buffer_len + 1, char);
        size_t value_len = strlen(value);
        int rc = zoo_create(pzk->handle, path, value, value_len, acl, flags, buffer, buffer_len);
        RETVAL = newSVpv(buffer, 0);
        Safefree(buffer);
        if (rc != ZOK) throw_zerror(aTHX_ rc, "Error creating node '%s': %s", path, zerror(rc));
    OUTPUT:
        RETVAL

void
delete(pzk_t* pzk, char* path, int version=-1)
    PPCODE:
        if (!pzk) Perl_croak(aTHX_ "handle has not yet been initialized by ZooKeeper");
        int rc = zoo_delete(pzk->handle, path, version);
        if (rc != ZOK) throw_zerror(aTHX_ rc, "Error deleting node '%s': %s", path, zerror(rc));

SV*
exists(pzk_t* pzk, char* path, pzk_watcher_t* watcher=NULL)
    CODE:
        if (!pzk) Perl_croak(aTHX_ "handle has not yet been initialized by ZooKeeper");

        int rc;
        struct Stat stat; Zero(&stat, 1, struct Stat);
        if (watcher) {
            rc = zoo_wexists(pzk->handle, path, pzk_dispatcher_cb, (void*) watcher, &stat);
        } else {
            rc = zoo_exists(pzk->handle, path, 0, &stat);
        }

        if (rc == ZOK) {
            RETVAL = stat_to_sv(aTHX_ &stat);
        } else if (rc == ZNONODE) {
            RETVAL = &PL_sv_undef;
        } else {
            throw_zerror(aTHX_ rc, "Error checking existence of node '%s': %s", path, zerror(rc));
        }
    OUTPUT:
        RETVAL

void
get_children(pzk_t* pzk, char* path, pzk_watcher_t* watcher=NULL)
    PPCODE:
        if (!pzk) Perl_croak(aTHX_ "handle has not yet been initialized by ZooKeeper");

        int rc;
        struct String_vector strings; Zero(&strings, 1, struct String_vector);
        if (watcher) {
            rc = zoo_wget_children(pzk->handle, path, pzk_dispatcher_cb, (void*) watcher, &strings);
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
            throw_zerror(aTHX_ rc, "Error getting children for node '%s': %s", path, zerror(rc));
        }

void
get(pzk_t* pzk, char* path, int buffer_len, pzk_watcher_t* watcher=NULL)
    PPCODE:
        if (!pzk) Perl_croak(aTHX_ "handle has not yet been initialized by ZooKeeper");

        int rc;
        char* buffer; Newxz(buffer, buffer_len + 1, char);
        struct Stat stat; Zero(&stat, 1, struct Stat);
        if (watcher) {
            rc = zoo_wget(pzk->handle, path, pzk_dispatcher_cb, watcher, buffer, &buffer_len, &stat);
        } else {
            rc = zoo_get(pzk->handle, path, 0, buffer, &buffer_len, &stat);
        }

        if (rc != ZOK) throw_zerror(aTHX_ rc, "Error getting data for node '%s': %s", path, zerror(rc));

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
        if (!pzk) Perl_croak(aTHX_ "handle has not yet been initialized by ZooKeeper");

        struct Stat stat; Zero(&stat, 1, struct Stat);
        int rc = zoo_set2(pzk->handle, path, data, strlen(data), version, &stat);
        if (rc != ZOK) throw_zerror(aTHX_ rc, "Error setting data for node '%s': %s", path, zerror(rc));
        RETVAL = stat_to_sv(aTHX_ &stat);

    OUTPUT:
        RETVAL

void
get_acl(pzk_t* pzk, char* path)
    PPCODE:
        if (!pzk) Perl_croak(aTHX_ "handle has not yet been initialized by ZooKeeper");

        struct Stat stat; Zero(&stat, 1, struct Stat);
        struct ACL_vector acl; Zero(&acl, 1, struct ACL_vector);
        int rc = zoo_get_acl(pzk->handle, path, &acl, &stat);

        ST(0) = sv_2mortal(acl_vector_to_sv(aTHX_ &acl));
        deallocate_ACL_vector(&acl);

        if (rc != ZOK) throw_zerror(aTHX_ rc, "Error getting acl for node '%s': %s", path, zerror(rc));

        if (GIMME_V == G_ARRAY) {
            ST(1) = sv_2mortal(stat_to_sv(aTHX_ &stat));
            XSRETURN(2);
        } else {
            XSRETURN(1);
        }

void
set_acl(pzk_t* pzk, char* path, SV* acl_sv, int version=-1)
    PPCODE:
        if (!pzk) Perl_croak(aTHX_ "handle has not yet been initialized by ZooKeeper");

        struct ACL_vector* acl = sv_to_acl_vector(aTHX_ acl_sv);
        int rc = zoo_set_acl(pzk->handle, path, version, acl);
        Safefree(acl->data);
        Safefree(acl);
        if (rc != ZOK) throw_zerror(aTHX_ rc, "Error setting acl for node '%s': %s", path, zerror(rc));

const clientid_t*
client_id(pzk_t* pzk)
    CODE:
        if (!pzk) Perl_croak(aTHX_ "handle has not yet been initialized by ZooKeeper");
        RETVAL = zoo_client_id(pzk->handle);
    OUTPUT:
        RETVAL


MODULE = ZooKeeper PACKAGE = ZooKeeper::Channel

void
_xs_init(SV* self)
    PPCODE:
        if (SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV) {
            pzk_dequeue_t* channel = new_pzk_dequeue();
            sv_magic(SvRV(self), Nullsv, PERL_MAGIC_ext, (const char*) channel, 0);
        }

void
DESTROY(pzk_dequeue_t* channel)
    PPCODE:
        if (channel) destroy_pzk_dequeue(channel);

int
size(pzk_dequeue_t* channel)
    CODE:
        if (!channel) Perl_croak(aTHX_ "channel has not yet been initialized by ZooKeeper::Channel");
        RETVAL = channel->size;
    OUTPUT:
        RETVAL

void
send(pzk_dequeue_t* channel, ...)
    PPCODE:
        if (!channel) Perl_croak(aTHX_ "channel has not yet been initialized by ZooKeeper::Channel");

        int i;
        for (i = 1; i < items; i++) {
            pzk_dequeue_push(channel, SvREFCNT_inc(ST(i)));
        }
        XSRETURN_YES;

SV*
recv(pzk_dequeue_t* channel)
    CODE:
        if (!channel) Perl_croak(aTHX_ "channel has not yet been initialized by ZooKeeper::Channel");

        SV* element = (SV*) pzk_dequeue_shift(channel);
        if (!element) element = &PL_sv_undef;
        RETVAL = element;
    OUTPUT:
        RETVAL


MODULE = ZooKeeper PACKAGE = ZooKeeper::Dispatcher

SV*
recv_event(pzk_dispatcher_t* dispatcher)
    CODE:
        if (!dispatcher) Perl_croak(aTHX_ "dispatcher has not yet been initialized by ZooKeeper::Dispatcher");

        if (!dispatcher->channel->size) XSRETURN_EMPTY;
        pzk_event_t* event = (pzk_event_t*) pzk_dequeue_shift(dispatcher->channel);
        RETVAL = event ? event_to_sv(aTHX_ event) : &PL_sv_undef;
        if (event) destroy_pzk_event(event);
    OUTPUT:
        RETVAL

int
send_event(pzk_dispatcher_t* dispatcher, pzk_watcher_t* watcher, SV* event_sv)
    CODE:
        if (!dispatcher) Perl_croak(aTHX_ "dispatcher has not yet been initialized by ZooKeeper::Dispatcher");

        pzk_event_t* event = sv_to_event(aTHX_ watcher->event_ctx, event_sv);
        RETVAL = pzk_dequeue_push(dispatcher->channel, event) == 0;
        if (event) dispatcher->notify(dispatcher);
    OUTPUT:
        RETVAL

void
DESTROY(pzk_dispatcher_t* dispatcher)
    PPCODE:
        if (dispatcher) {
            pzk_event_t* event;
            while ((event = (pzk_event_t*) pzk_dequeue_shift(dispatcher->channel))) {
                destroy_pzk_event(event);
            }
        }


MODULE = ZooKeeper PACKAGE = ZooKeeper::Dispatcher::Pipe

void
_xs_init(SV* self, pzk_dequeue_t* channel)
    PPCODE:
        if (SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV) {
            pzk_pipe_dispatcher_t* dispatcher = new_pzk_pipe_dispatcher(channel);
            sv_magic(SvRV(self), Nullsv, PERL_MAGIC_ext, (const char*) dispatcher, 0);
        }

int
fd(pzk_pipe_dispatcher_t* dispatcher)
    CODE:
        if (!dispatcher) Perl_croak(aTHX_ "dispatcher has not yet been initialized by ZooKeeper::Dispatcher::Pipe");
        RETVAL = dispatcher->fd[0];
    OUTPUT:
        RETVAL

int
read_pipe(pzk_pipe_dispatcher_t* dispatcher)
    CODE:
        if (!dispatcher) Perl_croak(aTHX_ "dispatcher has not yet been initialized by ZooKeeper::Dispatcher::Pipe");
        RETVAL = dispatcher->read_pipe(dispatcher);
    OUTPUT:
        RETVAL

void
DESTROY(pzk_pipe_dispatcher_t* dispatcher)
    PPCODE:
        if (dispatcher) destroy_pzk_pipe_dispatcher(dispatcher);


MODULE = ZooKeeper PACKAGE = ZooKeeper::Dispatcher::Interrupt

void
_xs_init(SV* self, pzk_dequeue_t* channel, interrupt_fn func, void* arg)
    PPCODE:
        if (SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV) {
            pzk_interrupt_dispatcher_t* dispatcher = new_pzk_interrupt_dispatcher(channel, func, arg);
            sv_magic(SvRV(self), Nullsv, PERL_MAGIC_ext, (const char*) dispatcher, 0);
        }

void
DESTROY(pzk_interrupt_dispatcher_t* dispatcher)
    PPCODE:
        if (dispatcher) destroy_pzk_interrupt_dispatcher(dispatcher);


MODULE = ZooKeeper PACKAGE = ZooKeeper::Watcher

void
_xs_init(SV* self, pzk_dispatcher_t* dispatcher, SV* cb)
    PPCODE:
        if (SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV) {
            pzk_watcher_t* watcher; Newxz(watcher, 1, pzk_watcher_t);
            watcher->dispatcher = dispatcher;
            watcher->event_ctx  = (void*) SvREFCNT_inc(cb);
            sv_magic(SvRV(self), Nullsv, PERL_MAGIC_ext, (const char*) watcher, 0);
        }

void
DESTROY(pzk_watcher_t* watcher)
    PPCODE:
        if (watcher) {
            SvREFCNT_dec(watcher->event_ctx);
            Safefree(watcher);
        }


MODULE = ZooKeeper PACKAGE = ZooKeeper::Constants

BOOT:
{
    HV* stash = gv_stashpv("ZooKeeper::Constants", GV_ADDWARN);

    newCONSTSUB(stash, "ZOK",                      newSViv(ZOK));
    newCONSTSUB(stash, "ZSYSTEMERROR",             newSViv(ZSYSTEMERROR));
    newCONSTSUB(stash, "ZRUNTIMEINCONSISTENCY",    newSViv(ZRUNTIMEINCONSISTENCY));
    newCONSTSUB(stash, "ZDATAINCONSISTENCY",       newSViv(ZDATAINCONSISTENCY));
    newCONSTSUB(stash, "ZCONNECTIONLOSS",          newSViv(ZCONNECTIONLOSS));
    newCONSTSUB(stash, "ZMARSHALLINGERROR",        newSViv(ZMARSHALLINGERROR));
    newCONSTSUB(stash, "ZUNIMPLEMENTED",           newSViv(ZUNIMPLEMENTED));
    newCONSTSUB(stash, "ZOPERATIONTIMEOUT",        newSViv(ZOPERATIONTIMEOUT));
    newCONSTSUB(stash, "ZBADARGUMENTS",            newSViv(ZBADARGUMENTS));
    newCONSTSUB(stash, "ZINVALIDSTATE",            newSViv(ZINVALIDSTATE));
    newCONSTSUB(stash, "ZAPIERROR",                newSViv(ZAPIERROR));
    newCONSTSUB(stash, "ZNONODE",                  newSViv(ZNONODE));
    newCONSTSUB(stash, "ZNOAUTH",                  newSViv(ZNOAUTH));
    newCONSTSUB(stash, "ZBADVERSION",              newSViv(ZBADVERSION));
    newCONSTSUB(stash, "ZNOCHILDRENFOREPHEMERALS", newSViv(ZNOCHILDRENFOREPHEMERALS));
    newCONSTSUB(stash, "ZNODEEXISTS",              newSViv(ZNODEEXISTS));
    newCONSTSUB(stash, "ZNOTEMPTY",                newSViv(ZNOTEMPTY));
    newCONSTSUB(stash, "ZSESSIONEXPIRED",          newSViv(ZSESSIONEXPIRED));
    newCONSTSUB(stash, "ZINVALIDCALLBACK",         newSViv(ZINVALIDCALLBACK));
    newCONSTSUB(stash, "ZINVALIDACL",              newSViv(ZINVALIDACL));
    newCONSTSUB(stash, "ZAUTHFAILED",              newSViv(ZAUTHFAILED));
    newCONSTSUB(stash, "ZCLOSING",                 newSViv(ZCLOSING));
    newCONSTSUB(stash, "ZNOTHING",                 newSViv(ZNOTHING));

    newCONSTSUB(stash, "ZOO_EPHEMERAL", newSViv(ZOO_EPHEMERAL));
    newCONSTSUB(stash, "ZOO_SEQUENCE",  newSViv(ZOO_SEQUENCE));

    newCONSTSUB(stash, "ZOO_OPEN_ACL_UNSAFE", acl_vector_to_sv(&ZOO_OPEN_ACL_UNSAFE));
    newCONSTSUB(stash, "ZOO_READ_ACL_UNSAFE", acl_vector_to_sv(&ZOO_READ_ACL_UNSAFE));
    newCONSTSUB(stash, "ZOO_CREATOR_ALL_ACL", acl_vector_to_sv(&ZOO_CREATOR_ALL_ACL));

    newCONSTSUB(stash, "ZOO_PERM_READ",   newSViv(ZOO_PERM_READ));
    newCONSTSUB(stash, "ZOO_PERM_WRITE",  newSViv(ZOO_PERM_WRITE));
    newCONSTSUB(stash, "ZOO_PERM_CREATE", newSViv(ZOO_PERM_CREATE));
    newCONSTSUB(stash, "ZOO_PERM_DELETE", newSViv(ZOO_PERM_DELETE));
    newCONSTSUB(stash, "ZOO_PERM_ADMIN",  newSViv(ZOO_PERM_ADMIN));
    newCONSTSUB(stash, "ZOO_PERM_ALL",    newSViv(ZOO_PERM_ALL));

    newCONSTSUB(stash, "ZOO_CREATED_EVENT",     newSViv(ZOO_CREATED_EVENT));
    newCONSTSUB(stash, "ZOO_DELETED_EVENT",     newSViv(ZOO_DELETED_EVENT));
    newCONSTSUB(stash, "ZOO_CHANGED_EVENT",     newSViv(ZOO_CHANGED_EVENT));
    newCONSTSUB(stash, "ZOO_CHILD_EVENT",       newSViv(ZOO_CHILD_EVENT));
    newCONSTSUB(stash, "ZOO_SESSION_EVENT",     newSViv(ZOO_SESSION_EVENT));
    newCONSTSUB(stash, "ZOO_NOTWATCHING_EVENT", newSViv(ZOO_NOTWATCHING_EVENT));

    newCONSTSUB(stash, "ZOO_EXPIRED_SESSION_STATE", newSViv(ZOO_EXPIRED_SESSION_STATE));
    newCONSTSUB(stash, "ZOO_AUTH_FAILED_STATE",     newSViv(ZOO_AUTH_FAILED_STATE));
    newCONSTSUB(stash, "ZOO_CONNECTING_STATE",      newSViv(ZOO_CONNECTING_STATE));
    newCONSTSUB(stash, "ZOO_ASSOCIATING_STATE",     newSViv(ZOO_ASSOCIATING_STATE));
    newCONSTSUB(stash, "ZOO_CONNECTED_STATE",       newSViv(ZOO_CONNECTED_STATE));
}

const char*
zerror(int c)

