package ZooKeeper::XUnit::Watcher;
use ZooKeeper::Dispatcher;
use Test::LeakTrace;
use Test::Class::Moose;

sub test_leaks {
    my ($self) = @_;

    no_leaks_ok {
        my @watchers;
        my $dispatcher = ZooKeeper::Dispatcher->new;
        push @watchers, $dispatcher->create_watcher('/' => sub {}, type => 'watcher-test');
        push @watchers, $dispatcher->create_watcher('/second' => sub {}, type => 'second-watcher-test');
    } 'no leaks creating watchers';
}

1;
