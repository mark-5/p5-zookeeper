package ZooKeeper::Dispatcher;
use ZooKeeper::XS;
use ZooKeeper::Channel;
use ZooKeeper::Watcher;
use AnyEvent;
use Moo;

has channel => (
    is      => 'ro',
    default => sub { ZooKeeper::Channel->new },
);

has watchers => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { {} },
);

has dispatch_cb => (
    is      => 'rw',
    default => sub {
        my ($self) = @_;
        return sub { $self->dispatch_event };
    },
);

sub create_watcher {
    my ($self, $path, $cb, %args) = @_;
    my $type = $args{type};
    my $watcher = ZooKeeper::Watcher->new(dispatcher => $self, cb => $cb);
    return $self->watchers->{$path}{$type}{$watcher} = $watcher;
}

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

sub wait {
    my ($self) = @_;
    my $cv = AnyEvent->condvar;

    my $event;
    $self->dispatch_cb(sub {
        $event = $self->dispatch_event;
        $cv->send;
    });
    $cv->recv;

    $self->dispatch_cb(sub { $self->dispatch_event });
    return $event;
}


1;
