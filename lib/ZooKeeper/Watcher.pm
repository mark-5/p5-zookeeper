package ZooKeeper::Watcher;
use ZooKeeper::XS;
use Moo;

has cb => (
    is       => 'ro',
    required => 1,
);

sub BUILD {
    my ($self) = @_;
    $self->_xs_init($self->cb);
}

1;
