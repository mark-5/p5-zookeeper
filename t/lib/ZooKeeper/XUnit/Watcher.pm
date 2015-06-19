package ZooKeeper::XUnit::Watcher;
use Module::Runtime qw(require_module);
use Try::Tiny;
use Test::LeakTrace;
use Test::Class::Moose;

our %dispatchers = (
    'ZooKeeper::Dispatcher::AnyEvent'  => sub { shift->new },
    'ZooKeeper::Dispatcher::Interrupt' => sub { shift->new },
    'ZooKeeper::Dispatcher::Pipe'      => sub { shift->new },
    'ZooKeeper::Dispatcher::IOAsync'   => sub {
        require IO::Async::Loop;
        $_[0]->new(loop => IO::Async::Loop->new);
    },
);

sub test_leaks {
    my ($self) = @_;

    while (my ($class, $constr) = each %dispatchers) {
        next unless try { require_module($class) };
        $self->_test_dispatcher_leaks($class, $constr);
    }
}

sub _test_dispatcher_leaks {
    my ($self, $class, $constr) = @_;
    no_leaks_ok {
        my @watchers;
        my $dispatcher = $class->$constr;
        push @watchers, $dispatcher->create_watcher('/' => sub {}, type => 'watcher-test');
        push @watchers, $dispatcher->create_watcher('/second' => sub {}, type => 'second-watcher-test');
    } "no leaks creating $class watchers";
}

1;
