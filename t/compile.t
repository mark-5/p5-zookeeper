use strict; use warnings;
use Test::More;

use_ok($_) for qw(
    ZooKeeper::XS
    ZooKeeper
    ZooKeeper::Channel
    ZooKeeper::Watcher
);

done_testing();
