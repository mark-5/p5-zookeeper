package ZooKeeper::XUnit::Dispatcher::IOAsync;
use Try::Tiny;
use Test::Class::Moose;

sub test_startup {
    my ($self) = @_;
    try {
        require IO::Async::Loop;
        require ZooKeeper::Dispatcher::IOAsync;
    } catch {
        $self->test_skip('Could not require ZooKeeper::Dispatcher::IOAsync');
    };
}

has loop => (
    is      => 'ro',
    lazy    => 1,
    default => sub { IO::Async::Loop->new },
);

sub new_future { shift->loop->new_future }

sub new_dispatcher {
    my ($self, @args) = @_;
    return ZooKeeper::Dispatcher::IOAsync->new(loop => $self->loop, @args);
}


with 'ZooKeeper::XUnit::Role::Dispatcher';
with 'ZooKeeper::XUnit::Role::LeakChecker';
1;
