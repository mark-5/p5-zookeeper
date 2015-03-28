package ZooKeeper::XUnit::Dispatcher::Interrupt;
use Test::Class::Moose;
with 'ZooKeeper::XUnit::Role::Dispatcher';

sub implementation { 'ZooKeeper::Dispatcher::Interrupt' }

1;
