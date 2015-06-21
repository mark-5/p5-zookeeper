#!/usr/bin/env perl
use strict; use warnings;
use FindBin::libs;
use POE;
use POE::Future;
use Test::More;
use ZooKeeper;
use ZooKeeper::Constants;
use ZooKeeper::XT::Utils;

POE::Kernel->run;

my $future = POE::Future->new;
my $zk = ZooKeeper->new(
    hosts      => test_hosts,
    dispatcher => 'POE',
    watcher    => sub { $future->done(shift) },
);
my $event; timeout 5, sub { $event = $future->get };

is $event->{state}, ZOO_CONNECTED_STATE, 'got state for connection event';
is $event->{type},  ZOO_SESSION_EVENT, 'got type for connection event';

done_testing;
