package ZooKeeper::XT::Role::CheckAll;
use Test::Class::Moose::Role;
use namespace::clean;

with qw(
    ZooKeeper::XT::Role::CheckACLs
    ZooKeeper::XT::Role::CheckSessionEvents
);

1;
