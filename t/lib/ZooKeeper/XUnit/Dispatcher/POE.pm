package ZooKeeper::XUnit::Dispatcher::POE;
use Try::Tiny;
use Test::Class::Moose;

sub load_poe {
        require POE::Kernel;
        POE::Kernel->import({loop => 'Select'});
        require POE;
        POE->import;
        POE::Kernel->run;
}

sub test_startup {
    my ($self) = @_;
    try {
        $self->load_poe;
        require POE::Future;
        require ZooKeeper::Dispatcher::POE;
    } catch {
        $self->test_skip('Could not require ZooKeeper::Dispatcher::POE');
    };
}

sub new_future { POE::Future->new }

sub new_dispatcher {
    my ($self, @args) = @_;
    return ZooKeeper::Dispatcher::POE->new(@args);
}


with 'ZooKeeper::XUnit::Role::Dispatcher';
1;
