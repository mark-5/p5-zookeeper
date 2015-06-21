#!/usr/bin/env perl
use strict; use warnings;
use IO::Async::Loop;
use FindBin::libs;
use Test::More;
use ZooKeeper;
use ZooKeeper::Constants;
use ZooKeeper::Dispatcher::IOAsync;
use ZooKeeper::XT::Utils;

my $loop = IO::Async::Loop->new;
my $disp = ZooKeeper::Dispatcher::IOAsync->new(loop => $loop);
my $zk = ZooKeeper->new(
    hosts      => test_hosts,
    dispatcher => $disp,
    watcher    => sub { },
);
my $event = $zk->wait(5);

is $event->{state}, ZOO_CONNECTED_STATE, 'got state for connection event';
is $event->{type},  ZOO_SESSION_EVENT,   'got type for connection event';

done_testing;
