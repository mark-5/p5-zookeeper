package ZooKeeper::XUnit::Dispatcher::AnyEvent;
use Test::Class::Moose;
with 'ZooKeeper::XUnit::Role::WithAnyEventFuture';
with 'ZooKeeper::XUnit::Role::Dispatcher';

sub new_dispatcher {
    my ($self, @args) = @_;
    require ZooKeeper::Dispatcher::AnyEvent;
    return ZooKeeper::Dispatcher::AnyEvent->new(@args);
}

1;
