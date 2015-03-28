package ZooKeeper::Constants;
use strict; use warnings;
use ZooKeeper::XS;
use parent 'Exporter';

=head1 NAME

ZooKeeper::Constants

=head1 DESCRIPTION

A class for importing the ZooKeeper C library's enums. Also contains the library's zerror function for retriving string representations of error codes.

By default ZooKeeper::Constants imports all enums into a package. Individual enums can also be exported, along with an export tag for classes of enums

=head1 EXPORT TAGS

=head2 errors

Error codes returned by the ZooKeeper C library. Includes the zerror function for returning a string corresponding to the error code.

    zerror

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

=head2 node_flags

Flags that may be used during node creation.

    ZOO_EPHEMERAL
    ZOO_SEQUENCE

=head2 acl_perms

ACL permissions that may be used for a nodes ACLS

    ZOO_PERM_READ
    ZOO_PERM_WRITE
    ZOO_PERM_CREATE
    ZOO_PERM_DELETE
    ZOO_PERM_ADMIN
    ZOO_PERM_ALL

=head2 acls

A predefined set of ACLs.

ACLs can also be constructed manually, as an arrayref of hashrefs, where hashrefs include keys for id, scheme, and perms.

    ZOO_OPEN_ACL_UNSAFE
    ZOO_READ_ACL_UNSAFE
    ZOO_CREATOR_ALL_ACL

=head2 events

Possible ZooKeeper event types. These are used for the type key of the event hashref, passed to ZooKeeper watcher callbacks.

    ZOO_CREATED_EVENT
    ZOO_DELETED_EVENT
    ZOO_CHANGED_EVENT
    ZOO_CHILD_EVENT
    ZOO_SESSION_EVENT
    ZOO_NOTWATCHING_EVENT

=head2 states

Possible ZooKeeper connection states. These are used for the state key of the event hashref, passed to ZooKeeper watcher callbacks.

    ZOO_EXPIRED_SESSION_STATE
    ZOO_AUTH_FAILED_STATE
    ZOO_CONNECTING_STATE
    ZOO_ASSOCIATING_STATE
    ZOO_CONNECTED_STATE

=head2 watchers

Types of ZooKeeper watchers.

    ZWATCHERTYPE_CHILDREN
    ZWATCHERTYPE_DATA
    ZWATCHERTYPE_ANY

=cut

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
    'watchers' => [qw(
        ZWATCHERTYPE_CHILDREN
        ZWATCHERTYPE_DATA
        ZWATCHERTYPE_ANY
    )],
);

our @EXPORT       = map {@{$EXPORT_TAGS{$_}}} keys %EXPORT_TAGS;
our @EXPORT_OK    = @EXPORT;
$EXPORT_TAGS{all} = \@EXPORT;

1;
