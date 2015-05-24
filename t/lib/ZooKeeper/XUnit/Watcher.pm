package ZooKeeper::XUnit::Watcher;
use ZooKeeper::Dispatcher::AnyEvent;
use ZooKeeper::Dispatcher::Interrupt;
use ZooKeeper::Dispatcher::Pipe;
use Test::LeakTrace;
use Test::Class::Moose;

sub test_leaks {
    my ($self) = @_;

    $self->_test_dispatcher_leaks($_) for qw(
        ZooKeeper::Dispatcher::AnyEvent
        ZooKeeper::Dispatcher::Interrupt
        ZooKeeper::Dispatcher::Pipe
    );
}

sub _test_dispatcher_leaks {
    my ($self, $impl) = @_;
    no_leaks_ok {
        my @watchers;
        my $dispatcher = $impl->new;
        push @watchers, $dispatcher->create_watcher('/' => sub {}, type => 'watcher-test');
        push @watchers, $dispatcher->create_watcher('/second' => sub {}, type => 'second-watcher-test');
    } "no leaks creating $impl watchers";
}

1;
