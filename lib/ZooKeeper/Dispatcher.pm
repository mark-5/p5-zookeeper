package ZooKeeper::Dispatcher;
use ZooKeeper::XS;
use ZooKeeper::Channel;
use ZooKeeper::Watcher;
use AnyEvent;
use Scalar::Util qw(weaken);
use Moo;

=head1 NAME

ZooKeeper::Dispatcher

=head1 DESCRIPTION

A parent class for event dispatchers to inherit from. Dispatchers directly handle callbacks for ZooKeeper C library, and manage the lifecycle of ZooKeeper::Watcher's.

=head1 ATTRIBUTES

=head2 channel

A ZooKeeper::Channel, used for sending event data from ZooKeeper C callbacks to perl.

=cut

has channel => (
    is      => 'ro',
    default => sub { ZooKeeper::Channel->new },
);

=head2 watchers

A hashref of all live watchers.

=cut

has watchers => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { {} },
);

=head2 dispatch_cb

The perl subroutine reference to be invoked whenever the dispatcher is notified of an event. Usually just calls dispatch_event.

=cut

has dispatch_cb => (
    is      => 'rw',
    default => sub {
        my ($self) = @_;
        weaken($self);
        return sub { $self->dispatch_event };
    },
);

=head1 METHODS

=head2 recv_event

Receive event data from the channel. Returns undef if no event data is available.

=head2 create_watcher

Create a new ZooKeeper::Watcher. This is the preferred way to instantiate watchers.

    my $watcher = $dispatcher->create_watcher($path, $cb, %args);

        REQUIRED $path - The path of the node to register the watcher on
        REQUIRED $cb   - A perl subroutine reference to be invoked with event data

        %args
            REQUIRED type - The type of event the watcher is for(e.g get_children, exists)

=cut

sub create_watcher {
    my ($self, $path, $cb, %args) = @_;
    my $type = $args{type};

    my $watcher;
    my $store = $self->watchers->{$path} ||= {};
    my $wrapped = sub {
        delete $store->{$type} unless $type eq 'default';
        goto &$cb;
    };

    $watcher = ZooKeeper::Watcher->new(dispatcher => $self, cb => $wrapped);
    $store->{$type} = $watcher;

    weaken($store);
    weaken($watcher);
    return $watcher;
}

=head2 dispatch_event

Read an event from the channel, and execute the corresponding watcher callback.

=cut

sub dispatch_event {
    my ($self) = @_;
    if (my $event = $self->recv_event) {
        my $cb = delete $event->{cb};
        $cb->($event);
        return $event;
    } else {
        return undef;
    }
}

=head2 wait

Synchronously dispatch one event. Returns the event hashref the watcher was called with.

=cut

sub wait {
    my ($self) = @_;
    weaken($self);

    my $cv = AnyEvent->condvar;
    $self->dispatch_cb(sub {
        my $event = $self->dispatch_event;
        $cv->send($event);
    });
    my $event = $cv->recv;

    $self->dispatch_cb(sub { $self->dispatch_event });
    return $event;
}

=head2 get_watcher

Return the ZooKeeper::Watcher instance for the given path and type.

    my $watcher = $dispatcher->get_watcher($path, $type);

=cut

sub get_watcher {
    my ($self, $path, $type) = @_;
    return $self->watchers->{$path}{$type};
}

=head2 remove_watchers

Remove ZooKeeper::Watcher instances for the given path. If type is specified, only watchers matching the path and type will be removed.

    $dispatcher->remove_watchers($path, $type)

        REQUIRED $path
        OPTIONAL $type

=cut

sub remove_watchers {
    my ($self, $path, $type) = @_;
    my $watchers = $self->watchers;
    if ($type) {
        delete $watchers->{$path}{$type};
    } else {
        delete $watchers->{$path};
    }
}

1;
