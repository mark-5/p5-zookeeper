package ZooKeeper::XUnit::Dispatcher::AnyEvent;
use Try::Tiny;
use Test::Class::Moose;

sub test_startup {
    my ($self) = @_;
    try {
        require AnyEvent::Future;
        require ZooKeeper::Dispatcher::AnyEvent;
    } catch {
        $self->test_skip('Could not require ZooKeeper::Dispatcher::AnyEvent');
    };
}

sub new_future { AnyEvent::Future->new }

sub new_dispatcher {
    my ($self, @args) = @_;
    return ZooKeeper::Dispatcher::AnyEvent->new(@args);
}


with 'ZooKeeper::XUnit::Role::Dispatcher';
with 'ZooKeeper::XUnit::Role::LeakChecker';
1;
