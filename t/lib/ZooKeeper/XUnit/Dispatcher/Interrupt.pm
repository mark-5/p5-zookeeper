package ZooKeeper::XUnit::Dispatcher::Interrupt;
use Try::Tiny;
use Test::Class::Moose;

sub test_startup {
    my ($self) = @_;
    try {
        require AnyEvent::Future;
        require ZooKeeper::Dispatcher::Interrupt;
    } catch {
        $self->test_skip('Could not require ZooKeeper::Dispatcher::Interrupt');
    };
}

sub new_future { AnyEvent::Future->new }

sub new_dispatcher {
    my ($self, @args) = @_;
    return ZooKeeper::Dispatcher::Interrupt->new(@args);
}


with 'ZooKeeper::XUnit::Role::Dispatcher';
with 'ZooKeeper::XUnit::Role::LeakChecker';
1;
