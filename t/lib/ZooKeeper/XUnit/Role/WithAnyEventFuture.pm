package ZooKeeper::XUnit::Role::WithAnyEventFuture;
use Test::Class::Moose::Role;

sub new_future {
    require AnyEvent::Future;
    return AnyEvent::Future->new
};


1;
