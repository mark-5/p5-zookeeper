package ZooKeeper::XUnit::Dispatcher::IOAsync;
use Test::Class::Moose;

sub new_future { shift->loop->new_future }

has loop => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        require IO::Async::Loop;
        return IO::Async::Loop->new;
    },
);

sub test_startup { shift->test_skip("TODO") }

sub new_dispatcher {
    my ($self, @args) = @_;
    require ZooKeeper::Dispatcher::IOAsync;
    return ZooKeeper::Dispatcher::IOAsync->new(loop => $self->loop, @args);
}

with 'ZooKeeper::XUnit::Role::Dispatcher';

1;
