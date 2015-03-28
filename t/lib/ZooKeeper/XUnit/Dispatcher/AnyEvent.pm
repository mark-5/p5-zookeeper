package ZooKeeper::XUnit::Dispatcher::AnyEvent;
use Test::Class::Moose;
with 'ZooKeeper::XUnit::Role::Dispatcher';

sub implementation { 'ZooKeeper::Dispatcher::AnyEvent' }

1;
