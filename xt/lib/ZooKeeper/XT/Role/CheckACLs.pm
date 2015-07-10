package ZooKeeper::XT::Role::CheckACLs;
use Digest::SHA ();
use Test::Fatal qw(exception);
use ZooKeeper;
use ZooKeeper::Constants;
use ZooKeeper::Test::Utils;
use Test::Class::Moose::Role;
use namespace::clean;

sub handle {
    my ($test) = @_;
    return ZooKeeper->new(
        hosts      => test_hosts,
        dispatcher => $test->new_dispatcher,
    );
}

sub digest {
    my ($data) = @_;
    my $digest = Digest::SHA::sha1_base64($data);
    $digest .= "=" while length($digest) % 4;
    return $digest;
}

sub test_acls {
    my ($test) = @_;

    my ($user, $pass) = qw(foo bar);

    my $zk = $test->handle;
    my $authenticated = $test->new_future;
    $zk->add_auth(
        digest  => "$user:$pass",
        watcher => $authenticated,
    );
    $authenticated->get;

    my $data = sprintf("test data %s", scalar rand);
    my $node = $zk->create("/_perl_zk_test-",
        acl => [{
            scheme => "digest",
            id     => join(":", $user, digest("$user:$pass")),
            perms  => ZOO_PERM_ALL,
        }],
        sequential => 1,
        value      => $data,
    );
    is scalar($zk->get($node)), $data;

    my $zk = $test->handle;
    $authenticated = $test->new_future;
    $zk->add_auth(
        digest  => "different:credentials",
        watcher => $authenticated,
    );
    $authenticated->get;

    cmp_ok(exception { $zk->get($node) }, "==", ZNOAUTH);
}

1;
