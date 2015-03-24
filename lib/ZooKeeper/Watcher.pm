package ZooKeeper::Watcher;
use ZooKeeper::XS;
use Moo;

has dispatcher => (
    is       => 'ro',
    weak_ref => 1,
    required => 1,
);

has cb => (
    is       => 'ro',
    required => 1,
);

sub BUILD {
    my ($self) = @_;
    $self->_xs_init($self->dispatcher, $self->cb);
}

1;
