#!/usr/bin/env perl
use strict; use warnings;
use AE;
use FindBin::libs;
use Test::More;
use ZooKeeper;
use ZooKeeper::Constants;
use ZooKeeper::XT::Utils;

my $cv = AE::cv;
my $zk = ZooKeeper->new(
    hosts      => test_hosts,
    dispatcher => 'Interrupt',
    watcher    => sub { $cv->send(shift) },
);
my $ticker = $zk->dispatcher->ticker;
my $event; timeout 5, sub { $event = $cv->recv };

is $event->{state}, ZOO_CONNECTED_STATE, 'got state for connection event';
is $event->{type},  ZOO_SESSION_EVENT,   'got type for connection event';

done_testing;
