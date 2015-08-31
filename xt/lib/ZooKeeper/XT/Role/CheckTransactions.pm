package ZooKeeper::XT::Role::CheckTransactions;
use ZooKeeper;
use ZooKeeper::Constants;
use ZooKeeper::Test::Utils;
use Test::Class::Moose::Role;
use namespace::clean;

sub test_create {
    my ($test) = @_;
    my $handle = ZooKeeper->new(
        hosts      => test_hosts,
        dispatcher => $test->new_dispatcher,
    );

    my $node = "/_perl_zk_test_txn_create-$$";

    my $txn = $handle->transaction
                     ->create("${node}-1", ephemeral => 1)
                     ->create("${node}-2", ephemeral => 1);

    my @results = $txn->commit;
    is_deeply \@results, [
        {
            path => "${node}-1",
            type => 'create',
        },
        {
            path => "${node}-2",
            type => 'create',
        },
    ], 'returned path and types for nods created in transaction';

    ok $handle->exists("${node}-1");
    ok $handle->exists("${node}-2");
}

sub test_bad_transaction {
    my ($test) = @_;
    my $handle = ZooKeeper->new(
        hosts      => test_hosts,
        dispatcher => $test->new_dispatcher,
    );

    my $node = "/_perl_zk_test_txn_create-$$";

    my $txn = $handle->transaction
                     ->create("${node}-1", ephemeral => 1)
                     ->create("${node}-2/bad-parent", ephemeral => 1);

    my @results = $txn->commit;

    is $results[0]->{type}, 'error', 'good op returned with type error';
    is $results[0]->{code}, ZOK,     'good op returned error code ZOK';
    is $results[1]->{type}, 'error', 'bad op returned with type error';
    is $results[1]->{code}, ZNONODE, 'bad op returned ZNONODE on bad create';

    ok !$handle->exists("${node}-1"), 'node from good op code not created';
    ok !$handle->exists("${node}-2/bad-parent"), 'node from bad op code not created';
}

1;
