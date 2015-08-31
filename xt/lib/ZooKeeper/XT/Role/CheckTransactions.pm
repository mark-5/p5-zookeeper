package ZooKeeper::XT::Role::CheckTransactions;
use ZooKeeper;
use ZooKeeper::Test::Utils;
use Test::Class::Moose::Role;
use namespace::clean;

sub test_setup {
    my ($test) = @_;
    my $test_method = $test->test_report->current_method;
 
    if ('test_error' eq $test_method->name) {
        $test->test_skip("TODO handle transaction errors");
    }
}

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
    ];

    ok $handle->exists("${node}-1");
    ok $handle->exists("${node}-2");
}

sub test_error {
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
}

1;
