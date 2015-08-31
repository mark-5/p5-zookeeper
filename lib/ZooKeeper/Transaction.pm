package ZooKeeper::Transaction;
use ZooKeeper::XS;
use ZooKeeper::Constants;
use Moo;

has handle => (
    is       => 'ro',
    weak_ref => 1,
    required => 1,
);

has ops => (
    is      => 'ro',
    default => sub { [] },
);

sub _add_op {
    my ($self, $type, @args) = @_;
    return ref($self)->new(
        handle => $self->handle,
        ops    => [
            @{$self->ops},
            [$type, @args],
        ],
    );
}

sub create {
    my ($self, $path, %extra) = @_;
    my ($value, $buffer_length, $acl) = @extra{qw(value buffer_length acl)};
    $value         //= '';
    $buffer_length //= $self->handle->buffer_length;
    $acl           //= ZOO_OPEN_ACL_UNSAFE;
    
    my $flags = 0;
    $flags |= ZOO_EPHEMERAL if $extra{ephemeral};
    $flags |= ZOO_SEQUENCE  if $extra{sequential};

    return $self->_add_op(ZOO_CREATE_OP, $path, $value, $buffer_length, $acl, $flags);
}

sub delete {
    my ($self, $path, %extra) = @_;
    my $version = $extra{version} // -1;
    return $self->_add_op(ZOO_DELETE_OP, $path, $version);
}

sub set {
    my ($self, $path, $value, %extra) = @_;
    my $version = $extra{version} // -1;
    return $self->_add_op(ZOO_SETDATA_OP, $path, $value, $version);
}

sub check {
    my ($self, $path, $version) = @_;
    return $self->_add_op(ZOO_CHECK_OP, $path, $version);
}

around commit => sub {
    my ($orig, $self) = @_;
    my $ops   = $self->ops;
    my $count = @$ops;
    return $self->$orig($self->handle, $count, $ops);
};

1;
