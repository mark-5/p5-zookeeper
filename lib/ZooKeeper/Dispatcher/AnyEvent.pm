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
