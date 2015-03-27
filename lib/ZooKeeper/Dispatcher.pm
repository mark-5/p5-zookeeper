package ZooKeeper::Dispatcher;
use ZooKeeper::XS;
use ZooKeeper::Channel;
use ZooKeeper::Watcher;
use AnyEvent;
use Scalar::Util qw(weaken);
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
        weaken($self);
        return sub { $self->dispatch_event };
    },
);

sub create_watcher {
    my ($self, $path, $cb, %args) = @_;
    my $type = $args{type};

    weaken(my $rwatcher = \my $watcher);
    weaken(my $store = $self->watchers->{$path}{$type} ||= {});
    my $wrapped = sub {
        delete $store->{$rwatcher} unless $type eq 'default';
        goto &$cb;
    };

    $watcher = ZooKeeper::Watcher->new(dispatcher => $self, cb => $wrapped);
    return $store->{$watcher} = $watcher;
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


1;
