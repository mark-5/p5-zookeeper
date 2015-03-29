package ZooKeeper;
use ZooKeeper::XS;
use ZooKeeper::Constants;
use Digest::SHA qw(sha1_base64);
use Carp;
use Moo;
use 5.10.1;

our $VERSION = '0.0.1';

=head1 NAME

ZooKeeper - Perl bindings for Apache ZooKeeper

=head1 SYNOPSIS

    my $zk = ZooKeeper->new(hosts => 'localhost:2181');

    my $cv = AE::cv;
    my @children = $zk->get_children('/', watcher => sub { my $event = shift; $cv->send($event) });
    my $child_event = $cv->recv;

=head1 DESCRIPTION

ZooKeeper is a perl interface to the Apache ZooKeeper C client library.

=head2 How is this different from Net::ZooKeeper?

=over 4

=item ZooKeeper is written for asynchronous programming.

To support asynchronous programs, watchers were implemented as code refs, which a ZooKeeper::Dispatcher asynchronously invokes with ZooKeeper event data. Conversely, Net::ZooKeeper used Net::ZooKeeper::Watch classes, which users must interact with using the wait method(which blocks).

=item ZooKeeper data is represented as normal perl data types.

ZooKeeper event and stat data are simply hashrefs and arrayrefs. Net::ZooKeeper instead provides specific perl classes for interacting with this data.

=item ZooKeeper leverages perl exception handling.

Instead of returning the C error codes, as Net::ZooKeeper does, ZooKeeper throws ZooKeeper::Error exceptions for unexpected return codes.

=back

=head2 Data Types

=over 4

=item acl

Acls are represented as an arrayrefs of hashrefs, where each hashref includes an id, scheme, and permissions. Permissions flags can be imported from the ZooKeeper::Constants package.

For instance, the ZOO_READ_ACL_UNSAFE would be represented as:

    [{id => 'anyone', scheme => 'world', perms => ZOO_PERM_READ}]

=item event

A hashref of attributes for a watcher event. Includes the type of event(a ZooKeeper::Constants event), connection state(a ZooKeeper::Constants state) and the path of the node triggering the event.

    {
        path  => '/child',
        state => ZOO_CONNECTED_STATE,
        type  => ZOO_CHILD_EVENT,
    }

=item stat

A hashref of fields from a C Stat struct.

    {
        aversion       => 0,
        ctime          => 0,
        cversion       => 0,
        czxid          => 0,
        ephemeralOwner => 0,
        dataLength     => 0,
        mtime          => 0,
        mzxid          => 0,
        numChildren    => 2,
        pzxid          => 2334,
        version        => 0,
    }

=back

=head1 ATTRIBUTES

=head2 hosts

A comma separated list of ZooKeeper server hostnames and ports.

    'localhost:2181'
    'zoo1.domain:2181,zoo2.domain:2181'

=cut

has hosts => (
    is       => 'ro',
    required => 1,
);

=head2 timeout

The session timout used for the ZooKeeper connection.

=cut

has timeout => (
    is      => 'ro',
    default => 10 * 10**3,
);

=head2 watcher

A subroutine reference to be called by a default watcher for the ZooKeeper session.

=cut

has watcher => (
    is => 'ro',
);

=head2 authentication

An arrayref used for authenticating with ZooKeeper. This will be passed as an array to add_auth.

    [$scheme, $credentials, %extra]

=cut

has authentication => (
    is => 'ro',
);

=head2 buffer_length

The default length of the buffer used for retrieving ZooKeeper data and paths. Defaults to 2048 bytes.

=cut

has buffer_length => (
    is      => 'ro',
    default => 2048,
);

=head2 dispatcher

The implementation of ZooKeeper::Dispatcher to be used.

Valid types include:
    AnyEvent  - ZooKeeper writes to a Unix pipe with an attached AnyEvent I/O watcher
    Interrupt - ZooKeeper uses Async::Interrupt callbacks

=cut

has dispatcher_type => (
    is       => 'ro',
    init_arg => 'dispatcher',
    default  => sub { $ENV{PERL_ZOOKEEPER_DISPATCHER} || 'AnyEvent' },
);

has dispatcher => (
    is       => 'rw',
    init_arg => undef,
    handles  => [qw(create_watcher wait)],
);

sub _build_dispatcher {
    my ($self) = @_;
    my $type  = lc $self->dispatcher_type;
    my $class = $type eq 'anyevent'  ? 'ZooKeeper::Dispatcher::AnyEvent'
              : $type eq 'interrupt' ? 'ZooKeeper::Dispatcher::Interrupt'
              : croak "Unrecognized dispatcher type: $type";

    unless (eval "require $class; 1") {
        croak "Could not require dispatcher class $class: $@";
    }

    return $class->new;
}

=head2 client_id

The client_id for a ZooKeeper session. Can be set during construction to resume a previous session.

=cut

sub BUILD {
    my ($self, $args) = @_;
    $self->dispatcher($self->_build_dispatcher);
    my $default_watcher = $self->watcher ? $self->create_watcher('' => $self->watcher, type => 'default') : undef;

    $self->_xs_init($self->hosts, $self->timeout, $default_watcher, $args->{client_id});

    if (my $auth = $self->authentication) {
        $self->add_auth(@$auth);
    }
}

=head1 METHODS

=head2 new

Instantiate a new ZooKeeper connection.

    my $zk = ZooKeeper->new(%args)

        %args
            REQUIRED hosts
            OPTIONAL authentication
            OPTIONAL buffer_length
            OPTIONAL dispatcher
            OPTIONAL timeout
            OPTIONAL watcher

=head2 wait

Calls wait on the underlying ZooKeeper::Dispatcher.

Synchronously dispatch one event. Returns the event hashref the watcher was called with.
Can optionally be passed a timeout(specified in seconds), which will cause wait to return undef if it does not complete in the specified time.

    my $event = $zk->wait($seconds)

    OPTIONAL $seconds


=head2 create

Create a new node with the given path and data. Returns the path for the newly created node on succes. Otherwise a ZooKeeper::Error is thrown.

    my $created_path = $zk->create($requested_path, $value, %extra);

        REQUIRED $requested_path
        OPTIONAL $value

        OPTIONAL %extra
            acl
            buffer_length
            persistent
            sequential

=cut

around create => sub {
    my ($orig, $self, $path, $value, %extra) = @_;
    my $flags = 0;
    $flags |= ZOO_EPHEMERAL if !$extra{persistent};
    $flags |= ZOO_SEQUENCE  if $extra{sequential};
    return $self->$orig($path, $value//'', $extra{buffer_length}//$self->buffer_length, $extra{acl}//ZOO_OPEN_ACL_UNSAFE, $flags);
};

=head2 add_auth

Add authentication credentials for the session. Will automatically be invoked if the authentication attribute was set during construction.
If the digest scheme is used, and encoded is not set, then credentials will be automatically hashed with Digest::SHA::sha1_base64.

A ZooKeeper::Error will be thrown if the request could not be made. To determine success or failure authenticating, a watcher must be passed.

    $zk->add_auth($scheme, $credentials, %extra)

        REQUIRED $scheme
        REQUIRED $credentials

        OPTIONAL %extra
            watcher
            encoded

=cut

around add_auth => sub {
    my ($orig, $self, $scheme, $credentials, %extra) = @_;
    $credentials = sha1_base64($credentials) if $scheme eq 'digest' and !$extra{encoded};
    my $watcher = $extra{watcher} ? $self->create_watcher('', $extra{watcher}, type => 'add_auth') : undef;
    return $self->$orig($scheme, $credentials, $watcher);
};

=head2 delete

Delete a node at the given path. Throws a ZooKeeper::Error if the delete was unsuccessful.

    $zk->delete($path, %extra)

        REQUIRED $path

        OPTIONAL %extra
            version

=cut

around delete => sub {
    my ($orig, $self, $path, %extra) = @_;
    return $self->$orig($path, $extra{version}//-1);
};

=head2 exists

Check whether a node exists at the given path, and optionally set a watcher for when the node is created or deleted.
On success, returns a stat hashref for the node. Otherwise returns undef.

    my $stat = $zk->exists($path, %extra)

        REQUIRED $path

        OPTIONAL %extra
            watcher

=cut

around exists => sub {
    my ($orig, $self, $path, %extra) = @_;
    my $watcher = $extra{watcher} ? $self->create_watcher($path, $extra{watcher}, type => 'exists') : undef;
    return $self->$orig($path, $watcher);
};

=head2 get_children

Get the children stored directly under the given path. Optionally set a watcher for when a child is created or deleted.
Returns an array of child path names.

    my @child_paths = $zk->get_children($path, %extra)

        REQUIRED $path

        OPTIONAL %extra
            watcher

=cut

around get_children => sub {
    my ($orig, $self, $path, %extra) = @_;
    my $watcher = $extra{watcher} ? $self->create_watcher($path, $extra{watcher}, type => 'get_children') : undef;
    return $self->$orig($path, $watcher);
};

=head2 get

Retrieve data stored at the given path. Optionally set a watcher for when the data is changed.
In list context, the data and stat hashref of the node is returned. Otherwise just the data is returned.

    my $data          = $zk->get($path, %extra)
    my ($data, $stat) = $zk->get($path, %extra)

        REQUIRED $path

        OPTIONAL %extra
            watcher
            buffer_length

=cut

around get => sub {
    my ($orig, $self, $path, %extra) = @_;
    my $watcher = $extra{watcher} ? $self->create_watcher($path, $extra{watcher}, type => 'get') : undef;
    return $self->$orig($path, $extra{buffer_length}//$self->buffer_length, $watcher);
};

=head2 set

Set data at the given path.
On succes, returns a stat hashref of the node. Otherwise a ZooKeeper::Error is thrown.

    my $stat = $zk->set($path => $value, %extra)

        REQUIRED $path
        REQUIRED $value

        OPTIONAL %extra
            version

=cut

around set => sub {
    my ($orig, $self, $path, $value, %extra) = @_;
    return $self->$orig($path, $value, $extra{version}//-1);
};

=head2 get_acl

Get ACLs for the given node.
Returns an ACLs arrayref on success, otherwise throws a ZooKeeper::Error

    my $acl = $zk->get_acl($path)

        REQUIRED $path

=head2 set_acl

Set ACls for a node at the given path.

    $zk->set_acl($path => $acl, %extra)

        REQUIRED $path

        OPTIONAL %extra
            version

=cut

around set_acl => sub {
    my ($orig, $self, $path, $acl, %extra) = @_;
    return $self->$orig($path, $acl, $extra{version}//-1);
};

=head1 CAVEATS

=head2 Forking

The underlying C library uses POSIX threads. This means that ZooKeeper is not fork safe. Only exec and POSIX::_exit can be guaranteed to work safely in the child process.

=head2 Signals

Many ZooKeeper recipes(such as in the examples directory), rely on clients properly shutting down to delete ephemeral nodes. Otherwise the ZooKeeper server will wait for the entire duration of the timeout specified by the session, before cleaning up. If you are expecting your program to handle signals(such as SIGINT), make sure the program is properly catching them and exiting. See the examples for more information.

=head1 SEE ALSO

The Apache ZooKeeper project's home page at
L<http://zookeeper.apache.org/> provides a wealth of detail
on how to develop applications using ZooKeeper.

=head1 AUTHOR

Mark Flickinger <maf@cpan.org>

=head1 LICENSE

This software is licensed under the same terms as Perl itself.

=cut

1;
