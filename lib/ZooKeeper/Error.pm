package ZooKeeper::Error;
use ZooKeeper::Constants qw(zerror);
use Moo;
with 'Throwable';

use overload '""' => \&stringify, fallback => 1;

has code => (
    is       => 'ro',
    required => 1,
);

has error => (
    is      => 'ro',
    default => sub { zerror(shift->code) },
);

has message => (
    is      => 'ro',
    default => sub { shift->error },
);

sub stringify { shift->message }

1;
