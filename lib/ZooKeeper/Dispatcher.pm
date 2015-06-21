package ZooKeeper::Dispatcher;
use ZooKeeper::XS;
use ZooKeeper::Channel;
use ZooKeeper::Constants qw(ZOO_SESSION_EVENT);
use ZooKeeper::Watcher;
use AnyEvent;
use Scalar::Util qw(weaken);
use Scope::Guard qw(guard);
use Moo;

=head1 NAME

ZooKeeper::Dispatcher

=head1 DESCRIPTION

A parent class for event dispatchers to inherit from. Dispatchers directly handle callbacks for ZooKeeper the C library, and manage the lifecycle of ZooKeeper::Watcher's.

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
        my $cb = sub { $self->dispatch_event };

        weaken($self);
        return $cb;
    },
);

=head2 ignore_session_events

Controls whether watchers should be triggered for session events.

=cut

has ignore_session_events => (
    is      => "rw",
    default => 1,
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
    my $default_watch = $type eq "default";

    my $watcher;
    my $wrapped = sub {
        my ($event) = @_;
        my $sess_event = $event->{type} == ZOO_SESSION_EVENT;
        if ($self->ignore_session_events) {
            return if $sess_event and not $default_watch;
        }
        if (not $sess_event and not $default_watch) {
            $self->remove_watcher(
                path    => $path,
                type    => $type,
                watcher => $watcher,
            );
        }
        goto &$cb;
    };

    $watcher = ZooKeeper::Watcher->new(dispatcher => $self, cb => $wrapped);
    $self->_add_watcher(
        path    => $path,
        type    => $type,
        watcher => $watcher,
    );

    weaken($self);
    weaken($watcher);
    return $watcher;
}

sub _add_watcher {
    my ($self, %args) = @_;
    my ($path, $type, $watcher) = @args{qw(path type watcher)};
    $self->watchers->{$path}{$type}{$watcher} = $watcher;
}

sub get_watchers {
    my ($self, %args) = @_;
    my ($path, $type) = @args{qw(path type)};
    return values %{$self->watchers->{$path}{$type}||{}};
}

sub remove_watcher {
    my ($self, %args) = @_;
    my ($path, $type, $watcher) = @args{qw(path type watcher)};
    delete $self->watchers->{$path}{$type}{$watcher};

    delete $self->watchers->{$path}{$type}
        unless keys %{$self->watchers->{$path}{$type}||{}};
    delete $self->watchers->{$path}
        unless keys %{$self->watchers->{$path}||{}};
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

around send_event => sub {
    my ($orig, $self, $event, $watcher) = @_;
    my ($type, $state, $path) = @{$event}{qw(type state path)};
    $self->$orig($type//0, $state//0, $path//'', $watcher);
};

=head2 trigger_event

Manually trigger an event on a ZooKeeper::Watch.

=cut

sub trigger_event {
    my ($self, %args) = @_;
    my ($event, $path, $type) = @args{qw(event path type)};

    my @watchers = values %{$self->watchers->{$path}{$type}||{}};
    $self->send_event($event//{}, $_) for @watchers;
}

=head2 wait

Synchronously dispatch one event. Returns the event hashref the watcher was called with.
Can optionally be passed a timeout(specified in seconds), which will cause wait to return undef if it does not complete in the specified time.

    my $event = $zk->wait($seconds)

    OPTIONAL $seconds

=cut

sub wait {
    my ($self, $time) = @_;

    my $cv = AnyEvent->condvar;
    my $w  = $time && do {
        AnyEvent->timer(after => $time, cb => sub { $cv->send })
    };

    my $dispatch_cb = $self->dispatch_cb;
    my $guard       = guard { $self->dispatch_cb($dispatch_cb) };
    $self->dispatch_cb(sub {
        my $event = $dispatch_cb->();
        $cv->send($event);
    });
    my $event = $cv->recv;

    weaken($self);
    return $event;
}


1;
