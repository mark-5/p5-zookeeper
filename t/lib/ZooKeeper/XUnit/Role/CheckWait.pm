package ZooKeeper::XUnit::Role::CheckWait;
use Try::Tiny;
use ZooKeeper::Constants qw(ZOO_CHILD_EVENT ZOO_SESSION_EVENT);
use ZooKeeper::XUnit::Utils qw(timeout);
use Test::Class::Moose::Role;
requires qw(new_delay new_dispatcher);

sub test_wait {
    my ($self) = @_;
    my $dispatcher = $self->new_dispatcher;

    $dispatcher->create_watcher('/' => sub { }, type => "test");

    my $finished = 0; timeout 1, sub { $dispatcher->wait; $finished++ };
    is $finished, 0, 'timed out waiting before event trigger';

    timeout 1, sub { $dispatcher->wait(2); $finished++ };
    is $finished, 0, 'timed out when passed long wait';

    timeout 2, sub { $dispatcher->wait(1); $finished++ };
    is $finished, 1, 'returned when passed short wait';

    my $rv; timeout 2, sub { $rv = $dispatcher->wait(1) };
    is $rv, undef, 'returned undef when no events';

    my $event = {type => 1, state => 2, path => 'test-path'};
    my $delay = $self->new_delay(1, sub {
        $dispatcher->trigger_event(
            path  => '/',
            type  => 'test',
            event => $event,
        )
    });
    timeout 5, sub { $rv = $dispatcher->wait };
    is_deeply $rv, $event, 'wait returned triggered event';
}

1;
