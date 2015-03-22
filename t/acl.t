use strict; use warnings;
use Test::More;
use Test::LeakTrace;

use_ok('ZooKeeper::ACL');
ZooKeeper::ACL->import;

my %constants = (
    'ZOO_OPEN_ACL_UNSAFE' => \&ZOO_OPEN_ACL_UNSAFE,
    'ZOO_READ_ACL_UNSAFE' => \&ZOO_READ_ACL_UNSAFE,
    'ZOO_CREATOR_ALL_ACL' => \&ZOO_CREATOR_ALL_ACL,
);

while (my ($name, $sub) = each %constants) {
    no_leaks_ok {
        $sub->();
    } "no leaks returning acl $name";
}

done_testing();
