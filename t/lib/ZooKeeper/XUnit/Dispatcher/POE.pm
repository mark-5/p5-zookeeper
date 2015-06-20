package ZooKeeper::XUnit::Dispatcher::POE;
use Test::Class::Moose;

sub new_future {
    require POE::Future;
    return POE::Future->new;
}

sub new_dispatcher {
    require ZooKeeper::Dispatcher::POE;
    return ZooKeeper::Dispatcher::POE->new;
}

with 'ZooKeeper::XUnit::Role::Dispatcher';

1;
