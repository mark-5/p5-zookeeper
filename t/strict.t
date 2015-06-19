use Test::Strict;
$Test::Strict::TEST_SKIP = [glob 'lib/ZooKeeper/Dispatcher/*'];
all_perl_files_ok(qw(lib));
