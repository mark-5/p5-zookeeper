package ZooKeeper::XUnit::Dispatcher::Interrupt;
use Test::Class::Moose;
with 'ZooKeeper::XUnit::Role::WithAnyEventFuture';
with 'ZooKeeper::XUnit::Role::Dispatcher';

sub new_dispatcher {
    my ($self, @args) = @_;
    require ZooKeeper::Dispatcher::Interrupt;
    return ZooKeeper::Dispatcher::Interrupt->new(@args);
}

1;
