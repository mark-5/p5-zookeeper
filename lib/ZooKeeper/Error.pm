package ZooKeeper::Error;
use ZooKeeper::Constants;
use Moo;
with 'Throwable';

use overload '""' => \&stringify, fallback => 1;

=head1 NAME

ZooKeeper::Error

=head1 DESCRIPTION

A Throwable class for ZooKeeper exceptions.

=head1 SYNOPSIS

    ZooKeeper::Error->throw({
        code    => ZNONODE,
        error   => 'no node',
        message => "Tried to delete a node that does not exist",
    })

=head1 ATTRIBUTES

=head2 code

The error code returned by the ZooKeeper C library. See ZooKeeper::Constants for possible error codes.

=cut

has code => (
    is       => 'ro',
    required => 1,
);

=head2 error

The string corresponding to the ZooKeeper error code, usually given by ZooKeeper::Constant::zerror($code)

=cut

has error => (
    is      => 'ro',
    default => sub { ZooKeeper::Constants::zerror(shift->code) },
);

=head2 message

A descriptive error message for the exception. This is what is returned when ZooKeeper::Error's are stringified.

=cut

has message => (
    is      => 'ro',
    default => sub { shift->error },
);

sub stringify { shift->message }

1;