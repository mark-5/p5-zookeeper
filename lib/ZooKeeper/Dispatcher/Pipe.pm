package ZooKeeper::Dispatcher::Pipe;
use ZooKeeper::XS;
use Moo;
extends 'ZooKeeper::Dispatcher';

after recv_event => sub { shift->read_pipe };

sub BUILD {
    my ($self) = @_;
    $self->_xs_init($self->channel);
}


1;
