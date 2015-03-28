package ZooKeeper::XUnit::Constants;
use ZooKeeper::Constants;
use Test::LeakTrace;
use Test::Class::Moose;

sub test_leaks {
    my %acl_constants = (
        'ZOO_OPEN_ACL_UNSAFE' => \&ZOO_OPEN_ACL_UNSAFE,
        'ZOO_READ_ACL_UNSAFE' => \&ZOO_READ_ACL_UNSAFE,
        'ZOO_CREATOR_ALL_ACL' => \&ZOO_CREATOR_ALL_ACL,
    );

    while (my ($name, $sub) = each %acl_constants) {
        no_leaks_ok {
            $sub->();
        } "no leaks returning acl $name";
    }
}


1;
