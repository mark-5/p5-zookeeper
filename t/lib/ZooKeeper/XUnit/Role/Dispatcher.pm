package ZooKeeper::XUnit::Role::Dispatcher;
use AnyEvent;
use Test::LeakTrace;
use Try::Tiny;
use Test::Class::Moose::Role;
requires qw(implementation);

sub timeout {
    my ($time, $code) = @_;
    my $timeout = "TIMEOUT\n";

    my $timedout = try {
        local $SIG{ALRM} = sub { die $timeout };
        alarm($time);
        $code->();
        alarm(0);
    } catch {
        die $_ unless $_ eq $timeout;
    };
    alarm(0);
}

sub test_startup {
    my ($self) = @_;
    my $impl = $self->implementation;
    eval "require $impl; 1" or die "Could not require dispatcher implementation '$impl': $@";
}

sub test_dispatcher {
    my ($self) = @_;

    my $dispatcher = $self->implementation->new;

    my $cv = AnyEvent->condvar;
    my $watch = $dispatcher->create_watcher('/' => sub{ $cv->send(shift) }, type => 'test');
    my $event = {type => 1, state => 2, path => 'test-path'};
    $dispatcher->send_event($watch => $event);

    my $rv; timeout 1, sub { $rv = $cv->recv };
    is_deeply $rv, $event, 'dispatcher called watcher with event';


    $cv = AnyEvent->condvar;
    $watch = $dispatcher->create_watcher('/second' => sub{ $cv->send(shift) }, type => 'second-test');
    $event = {type => 2, state => 3, path => 'second-test-path'};
    $dispatcher->send_event($watch => $event);

    timeout 1, sub { $rv = $cv->recv };
    is_deeply $rv, $event, 'dispatcher called second watcher with event';
}

sub test_leaks {
    my ($self) = @_;
    no_leaks_ok { $self->implementation->new } 'no leaks constructing dispatcher';

    no_leaks_ok {
        my $dispatcher = $self->implementation->new;

        my $cv = AnyEvent->condvar;
        my $watch = $dispatcher->create_watcher('/' => sub{ $cv->send }, type => 'test');
        $dispatcher->send_event($watch => {});
        timeout 1, sub { $cv->recv };

        $cv = AnyEvent->condvar;
        $watch = $dispatcher->create_watcher('/second' => sub{ $cv->send }, type => 'second-test');
        $dispatcher->send_event($watch => {});
        timeout 1, sub { $cv->recv };
    } 'no leaks sending events through dispatcher';
}

1;
