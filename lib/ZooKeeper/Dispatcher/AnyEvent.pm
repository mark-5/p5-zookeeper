package ZooKeeper::Dispatcher::AnyEvent;
use AnyEvent;
use Scalar::Util qw(weaken);
use Moo;
extends 'ZooKeeper::Dispatcher::Pipe';

has ae_watcher => (
    is        => 'rw',
    clearer   => 1,
    predicate => 1,
);

around dispatch_event => sub {
    my ($orig, $self, @args) = @_;
    $self->clear_ae_watcher;
    my $event = $self->$orig(@args);
    $self->setup_ae_watcher;
    return $event;
};

sub setup_ae_watcher {
    my ($self) = @_;
    weaken($self);

    my $w = AnyEvent->io(
        fh   => $self->fd,
        poll => 'r',
        cb   => sub { $self->dispatch_cb->() },
    );
    $self->ae_watcher($w);
}

sub BUILD {
    my ($self) = @_;
    $self->setup_ae_watcher;
}


1;
