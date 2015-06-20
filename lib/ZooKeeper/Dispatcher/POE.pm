package ZooKeeper::Dispatcher::POE;
use POE;
use Scalar::Util qw(weaken);
use Moo;
extends 'ZooKeeper::Dispatcher::Pipe';

has fh => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_fh',
);
sub _build_fh {
    my ($self) = @_;
    open my($fh), '<&=', $self->fd;
    return $fh;
}

sub BUILD {
    my ($self) = @_;
    weaken($self);

    my %states = (
        _start => sub {
            my $kernel = $_[KERNEL];
            $kernel->select_read($self->fh, 'dispatch');
        },
        dispatch => sub { $self->dispatch_cb->() },
    );

    POE::Session->create(inline_states => \%states);
    POE::Kernel->run();
}

1;
