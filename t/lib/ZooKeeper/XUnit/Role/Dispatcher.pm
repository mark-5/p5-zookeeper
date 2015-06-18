package ZooKeeper::XUnit::Role::Dispatcher;
use AnyEvent;
use Test::LeakTrace;
use Try::Tiny;
use Test::Class::Moose::Role;
use ZooKeeper::Constants qw(ZOO_CHILD_EVENT ZOO_SESSION_EVENT);
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
    $dispatcher->create_watcher('/' => sub{ $cv->send(shift) }, type => "test");
    my $event = {type => 1, state => 2, path => 'test-path'};
    $dispatcher->trigger_event(path => "/", type => "test", event => $event);

    my $rv; timeout 1, sub { $rv = $cv->recv };
    is_deeply $rv, $event, "dispatcher called watcher with event";


    $cv = AnyEvent->condvar;
    $dispatcher->create_watcher("/second" => sub{ $cv->send(shift) }, type => "second-test");
    $event = {type => 2, state => 3, path => "second-test-path"};
    $dispatcher->trigger_event(
        path  => "/second",
        type  => "second-test",
        event => $event
    );

    timeout 1, sub { $rv = $cv->recv };
    is_deeply $rv, $event, "dispatcher called second watcher with event";
}

sub test_leaks {
    my ($self) = @_;
    no_leaks_ok { $self->implementation->new } 'no leaks constructing dispatcher';

    my $dispatcher = $self->implementation->new;
    no_leaks_ok {
        my $cv = AnyEvent->condvar;
        $dispatcher->create_watcher("/" => sub{ $cv->send }, type => "test");
        $dispatcher->trigger_event(path => "/", type => "test");
        timeout 1, sub { $cv->recv };

        $cv = AnyEvent->condvar;
        $dispatcher->create_watcher("/second" => sub{ $cv->send }, type => "second-test");
        $dispatcher->trigger_event(path => "/second", type => "second-test");
        timeout 1, sub { $cv->recv };
    } 'no leaks sending events through dispatcher';
}

sub test_session_events {
    my ($self) = @_;
    my $dispatcher = $self->implementation->new(ignore_session_events => 0);

    my $cv = AnyEvent->condvar;
    $dispatcher->create_watcher("/" => sub{ $cv->send(shift) }, type => "test");

    my $event = {type => ZOO_SESSION_EVENT, state => 2, path => "/"};
    $dispatcher->trigger_event(path => "/", type => "test", event => $event);
    my $rv; timeout 1, sub { $rv = $cv->recv };
    is_deeply $rv, $event, "dispatcher called watcher with session event";

    $cv = AnyEvent->condvar;
    $event->{type} = ZOO_CHILD_EVENT;
    $dispatcher->trigger_event(path => "/", type => "test", event => $event);
    timeout 1, sub { $rv = $cv->recv };
    is_deeply $rv, $event, "dispatcher called watcher with additional watcher event";
}

sub test_ignore_session_events {
    my ($self) = @_;
    my $dispatcher = $self->implementation->new(ignore_session_events => 1);

    my $cv = AnyEvent->condvar;
    $dispatcher->create_watcher("/" => sub{ $cv->send(shift) }, type => "test");

    my $event = {type => ZOO_SESSION_EVENT, state => 2, path => "/"};
    $dispatcher->trigger_event(path => "/", type => "test", event => $event);
    my $rv; timeout 1, sub { $rv = $cv->recv };
    is_deeply $rv, undef, "dispatcher ignored session event";

    $cv = AnyEvent->condvar;
    $event->{type} = ZOO_CHILD_EVENT;
    $dispatcher->trigger_event(path => "/", type => "test", event => $event);
    timeout 1, sub { $rv = $cv->recv };
    is_deeply $rv, $event, "dispatcher called watcher with watcher event";
}

sub test_duplicate_watchers {
    my ($self) = @_;
    my $dispatcher = $self->implementation->new;

    my $cv1 = AnyEvent->condvar;
    $dispatcher->create_watcher('/' => sub{ $cv1->send(shift) }, type => "test");
    my $cv2 = AnyEvent->condvar;
    $dispatcher->create_watcher("/" => sub{ $cv2->send(shift) }, type => "test");

    my $event = {type => 1, state => 2, path => 'test-path'};
    $dispatcher->trigger_event(path => "/", type => "test", event => $event);

    my $rv; timeout 1, sub { $rv = $cv1->recv };
    is_deeply $rv, $event, "dispatcher called first watcher with event";

    $rv = undef; timeout 1, sub { $rv = $cv2->recv };
    is_deeply $rv, $event, "dispatcher called duplicate watcher with event";
}

sub test_duplicate_watchers_leaks {
    my ($self) = @_;
    my $dispatcher = $self->implementation->new;

    no_leaks_ok {
        my $cv1 = AnyEvent->condvar;
        $dispatcher->create_watcher("/" => sub{ $cv1->send }, type => "test");

        my $cv2 = AnyEvent->condvar;
        $dispatcher->create_watcher("/" => sub{ $cv2->send }, type => "test");

        $dispatcher->trigger_event(path => "/", type => "test");
        timeout 1, sub { $cv1->recv };
        timeout 1, sub { $cv2->recv };
    } 'no leaks with duplicate watchers';
}

1;
