#ifndef PZK_XS_UTILS_H_
#define PZK_XS_UTILS_H_

struct ACL* sv_to_acl_entry(pTHX_ SV* acl_sv) {
    if (!SvROK(acl_sv) || !(SvRV(acl_sv)) == SVt_PVHV)
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

#endif // ifndef PZK_XS_UTILS_H_
