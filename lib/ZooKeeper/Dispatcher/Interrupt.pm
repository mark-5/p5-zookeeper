package ZooKeeper::Dispatcher::Interrupt;
use ZooKeeper::XS;
use AnyEvent;
use Async::Interrupt;
use Moo;
extends 'ZooKeeper::Dispatcher';

has interrupt => (
    is      => 'ro',
    builder => '_build_interrupt',
);

sub _build_interrupt {
    my ($self) = @_;
    return Async::Interrupt->new(cb => sub { $self->dispatch_cb->() });
}

around wait => sub {
    my ($orig, $self) = @_;
    my $tick   = 0.1;
    my $ticker = AnyEvent->timer(after => $tick, interval => $tick, cb => sub {});
    $self->$orig();
};

sub BUILD {
    my ($self) = @_;
    my ($func, $arg) = $self->interrupt->signal_func;
    $self->_xs_init($self->channel, $func, $arg);
}


1;
