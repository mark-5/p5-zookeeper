package ZooKeeper::Watcher;
use ZooKeeper::XS;
use Moo;

=head1 NAME

ZooKeeper::Watcher

=head1 DESCRIPTION

A perl class for constructing the watcher contexts passed to the ZooKeeper C library.

=head1 ATTRIBUTES

=head2 dispatcher

A weak reference to the dispatcher the watcher belongs to.
Needed in order for the watcher to notify the dispatcher when it has been triggered.

=cut

has dispatcher => (
    is       => 'ro',
    weak_ref => 1,
    required => 1,
);

=head2 cb

A perl subroutine reference. Invoked with an event hashref, when the watch is triggered by the ZooKeeper C library.

    sub {
        my ($event) = @_;
        my $path  = $event->{path};
        my $type  = $event->{type};
        my $state = $event->{state};
    }

=cut

has cb => (
    is       => 'ro',
    required => 1,
);

=head1 METHODS

=head2 trigger

Manually trigger an event on a watch.

=cut

around trigger => sub {
    my ($orig, $self, $event) = @_;
    my ($path, $state, $type) = @{$event}{qw(path state type)};
    return $self->$orig($path//"", $state//0, $type//0);
};

sub BUILD {
    my ($self) = @_;
    $self->_xs_init($self->dispatcher, $self->cb);
}

1;
