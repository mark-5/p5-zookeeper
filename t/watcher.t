use strict; use warnings;
use Test::More;
use Test::LeakTrace;

use_ok('ZooKeeper::Watcher');
can_ok('ZooKeeper::Watcher', 'new');
isa_ok(ZooKeeper::Watcher->new(cb => sub {}), 'ZooKeeper::Watcher');

no_leaks_ok {
    my $watcher = ZooKeeper::Watcher->new(cb => sub {});
} 'no leaks constructing watcher';

done_testing;
