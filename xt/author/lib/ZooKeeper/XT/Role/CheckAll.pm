package ZooKeeper::XT::Role::CheckAll;
use Test::Class::Moose::Role;
use namespace::clean;

with qw(
    ZooKeeper::XT::Role::CheckACLs
    ZooKeeper::XT::Role::CheckCreate
    ZooKeeper::XT::Role::CheckForking
    ZooKeeper::XT::Role::CheckSessionEvents
    ZooKeeper::XT::Role::CheckSet
    ZooKeeper::XT::Role::CheckTransactions
);

around test_startup => sub {
    my ($orig, $test, @args) = @_;
    if ($ENV{CI}) {
        $test->test_skip('TODO: figure out how to run travis-ci with service dependencies');
    }
    return $test->$orig(@args);
};

1;
