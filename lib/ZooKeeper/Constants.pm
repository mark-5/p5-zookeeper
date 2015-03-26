package ZooKeeper::Constants;
use strict; use warnings;
use ZooKeeper::XS;
use parent 'Exporter';

our %EXPORT_TAGS = (
    'errors' => [qw(
        ZOK
        ZSYSTEMERROR
        ZRUNTIMEINCONSISTENCY
        ZDATAINCONSISTENCY
        ZCONNECTIONLOSS
        ZMARSHALLINGERROR
        ZUNIMPLEMENTED
        ZOPERATIONTIMEOUT
        ZBADARGUMENTS
        ZINVALIDSTATE
        ZAPIERROR
        ZNONODE
        ZNOAUTH
        ZBADVERSION
        ZNOCHILDRENFOREPHEMERALS
        ZNODEEXISTS
        ZNOTEMPTY
        ZSESSIONEXPIRED
        ZINVALIDCALLBACK
        ZINVALIDACL
        ZAUTHFAILED
        ZCLOSING
        ZNOTHING
        zerror
    )],
    'node_flags' => [qw(
        ZOO_EPHEMERAL
        ZOO_SEQUENCE
    )],
    'acl_perms' => [qw(
        ZOO_PERM_READ
        ZOO_PERM_WRITE
        ZOO_PERM_CREATE
        ZOO_PERM_DELETE
        ZOO_PERM_ADMIN
        ZOO_PERM_ALL
    )],
    'acls' => [qw(
        ZOO_OPEN_ACL_UNSAFE
        ZOO_READ_ACL_UNSAFE
        ZOO_CREATOR_ALL_ACL
    )],
    'events' => [qw(
        ZOO_CREATED_EVENT
        ZOO_DELETED_EVENT
        ZOO_CHANGED_EVENT
        ZOO_CHILD_EVENT
        ZOO_SESSION_EVENT
        ZOO_NOTWATCHING_EVENT
    )],
    'states' => [qw(
        ZOO_EXPIRED_SESSION_STATE
        ZOO_AUTH_FAILED_STATE
        ZOO_CONNECTING_STATE
        ZOO_ASSOCIATING_STATE
        ZOO_CONNECTED_STATE
    )],
);

our @EXPORT       = map {@{$EXPORT_TAGS{$_}}} keys %EXPORT_TAGS;
our @EXPORT_OK    = @EXPORT;
$EXPORT_TAGS{all} = \@EXPORT;

1;
