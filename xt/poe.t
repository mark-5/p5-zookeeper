#!/usr/bin/env perl
use strict; use warnings;
use FindBin::libs;
use POE;
use Test::More;
use ZooKeeper;
use ZooKeeper::Constants;
use ZooKeeper::XT::Utils;

POE::Kernel->run;

my $zk = ZooKeeper->new(
    hosts      => test_hosts,
    dispatcher => 'POE',
    watcher    => sub { },
);
my $event = $zk->wait(5);

is $event->{state}, ZOO_CONNECTED_STATE, 'got state for connection event';
is $event->{type},  ZOO_SESSION_EVENT,   'got type for connection event';

done_testing;
