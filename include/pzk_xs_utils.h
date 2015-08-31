#ifndef PZK_XS_UTILS_H_
#define PZK_XS_UTILS_H_
#include <stdarg.h>

void* _tied_object_to_ptr(pTHX_ SV* obj_sv, const char* var, const char* pkg, int unsafe) {
    if (!SvROK(obj_sv) || (SvTYPE(SvRV(obj_sv)) != SVt_PVHV)) {
        if (unsafe) return NULL;
        Perl_croak(aTHX_ "%s is not a blessed reference of type %s", var, pkg);
    }

    SV* tied_hash = SvRV(obj_sv);
    MAGIC* ext_magic = mg_find(tied_hash, PERL_MAGIC_ext);
    if (!ext_magic) {
        if (unsafe) return NULL;
        Perl_croak(aTHX_ "%s has not been initialized by %s", var, pkg);
    }

    return  (void*) ext_magic->mg_ptr;
}

void* unsafe_tied_object_to_ptr(pTHX_ SV* obj_sv) {
    return _tied_object_to_ptr(aTHX_ obj_sv, NULL, NULL, 1);
}

void* tied_object_to_ptr(pTHX_ SV* obj_sv, const char* var, const char* pkg) {
    return _tied_object_to_ptr(aTHX_ obj_sv, var, pkg, 0);
}

SV* ptr_to_tied_object(pTHX_ void* ptr, const char* pkg) {
    HV* stash = gv_stashpv(pkg, GV_ADDWARN);
    SV* attr_hash = (SV*) newHV();
    sv_magic(attr_hash, Nullsv, PERL_MAGIC_ext, (const char*) ptr, 0);
    return sv_bless(newRV_noinc(attr_hash), stash);
}

struct ACL* sv_to_acl_entry(pTHX_ SV* acl_sv) {
    if (!SvROK(acl_sv) || (SvTYPE(SvRV(acl_sv)) != SVt_PVHV))
        Perl_croak(aTHX_ "acl entry must be a hash ref");
    HV* acl_hv = (HV*) SvRV(acl_sv);
    struct ACL* acl_entry; Newxz(acl_entry, 1, struct ACL);

    SV** perm_val_ptr = hv_fetch(acl_hv, "perms", 5, 0);
    if (perm_val_ptr) acl_entry->perms = SvIV(*perm_val_ptr);

    SV** scheme_val_ptr = hv_fetch(acl_hv, "scheme", 6, 0);
    if (scheme_val_ptr) acl_entry->id.scheme = SvPV_nolen(*scheme_val_ptr);

    SV** id_val_ptr = hv_fetch(acl_hv, "id", 2, 0);
    if (id_val_ptr) acl_entry->id.id = SvPV_nolen(*id_val_ptr);

    return acl_entry;
}

struct ACL_vector* sv_to_acl_vector(pTHX_ SV* acl_v_sv) {
    if (!SvROK(acl_v_sv) || !(SvTYPE(SvRV(acl_v_sv)) == SVt_PVAV))
        Perl_croak(aTHX_ "acl must be an array ref of hash refs");
    AV* acl_v_av = (AV*) SvRV(acl_v_sv);
    SSize_t length = av_len(acl_v_av) + 1;

    struct ACL_vector *v;
    Newxz(v, 1, struct ACL_vector);
    Newxz(v->data, length, struct ACL);
    int i; for (i = 0; i < length; i++) {
        SV* acl_sv = *(av_fetch(acl_v_av, i, 0));
        v->data[i] = *(sv_to_acl_entry(aTHX_ acl_sv));
    }
    v->count = length;

    return v;
}

SV* acl_entry_to_sv(pTHX_ struct ACL* acl_entry) {
    HV* acl_hv = newHV();

    hv_store(acl_hv, "perms", 5, newSViv(acl_entry->perms), 0);
    hv_store(acl_hv, "scheme", 6, newSVpv(acl_entry->id.scheme, 0), 0);
    hv_store(acl_hv, "id", 2, newSVpv(acl_entry->id.id, 0), 0);

    return newRV_noinc((SV*) acl_hv);
}

SV* acl_vector_to_sv(pTHX_ struct ACL_vector* acl_v) {
    AV* acl_v_av = newAV();
    int32_t length = acl_v->count;

    int i; for (i = 0; i < length; i++) {
        struct ACL* acl_entry = &acl_v->data[i];
        av_push(acl_v_av, acl_entry_to_sv(aTHX_ acl_entry));
    }

    return newRV_noinc((SV*) acl_v_av);
}

SV* stat_to_sv(pTHX_ struct Stat* stat) {
    HV* stat_hv = newHV();

    hv_store(stat_hv, "czxid",          5,  newSViv(stat->czxid),          0);
    hv_store(stat_hv, "mzxid",          5,  newSViv(stat->mzxid),          0);
    hv_store(stat_hv, "ctime",          5,  newSViv(stat->ctime),          0);
    hv_store(stat_hv, "mtime",          5,  newSViv(stat->mtime),          0);
    hv_store(stat_hv, "version",        7,  newSViv(stat->version),        0);
    hv_store(stat_hv, "cversion",       8,  newSViv(stat->cversion),       0);
    hv_store(stat_hv, "aversion",       8,  newSViv(stat->aversion),       0);
    hv_store(stat_hv, "ephemeralOwner", 14, newSViv(stat->ephemeralOwner), 0);
    hv_store(stat_hv, "dataLength",     10, newSViv(stat->dataLength),     0);
    hv_store(stat_hv, "numChildren",    11, newSViv(stat->numChildren),    0);
    hv_store(stat_hv, "pzxid",          5,  newSViv(stat->pzxid),          0);

    return newRV_noinc((SV*) stat_hv);
}

SV* event_to_sv(pTHX_ pzk_event_t* event) {
    HV* event_hv = newHV();

    hv_store(event_hv, "type", 4, newSViv(event->type), 0);
    hv_store(event_hv, "state", 5, newSViv(event->state), 0);
    hv_store(event_hv, "path", 4, newSVpv(event->path, 0), 0);
    hv_store(event_hv, "cb", 2, SvREFCNT_inc((SV*) event->arg), 0);

    return newRV_noinc((SV*) event_hv);
}

pzk_event_t* sv_to_event(pTHX_ void* cb, SV* event_sv) {
    if (!SvROK(event_sv) || (SvTYPE(SvRV(event_sv)) != SVt_PVHV))
        Perl_croak(aTHX_ "entry entry must be a hash ref");
    HV* event_hv = (HV*) SvRV(event_sv);

    SV** type_val_ptr = hv_fetch(event_hv, "type", 4, 0);
    int type = type_val_ptr ? SvIV(*type_val_ptr) : -1;

    SV** state_val_ptr = hv_fetch(event_hv, "state", 5, 0);
    int state = state_val_ptr ? SvIV(*state_val_ptr) : -1;

    SV** path_val_ptr= hv_fetch(event_hv, "path", 4, 0);
    char* path = path_val_ptr ? SvPV_nolen(*path_val_ptr) : NULL;

    return new_pzk_event(type, state, path, cb);
}

void throw_zerror(pTHX_ int rc, const char* fmt, ...) {
    dSP;

    ENTER;
    SAVETMPS;

    HV* args_hv = newHV();
    hv_store(args_hv, "code", 4, newSViv(rc), 0);

    va_list args; va_start(args, fmt);
    hv_store(args_hv, "message", 7, newSVsv(vmess(fmt, &args)), 0);
    va_end(args);

    SV* args_sv = newRV_noinc((SV*) args_hv);

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv("ZooKeeper::Error", 0)));
    XPUSHs(sv_2mortal(args_sv));
    PUTBACK;

    call_method("throw", G_DISCARD);

    FREETMPS;
    LEAVE;
}

#endif // ifndef PZK_XS_UTILS_H_
