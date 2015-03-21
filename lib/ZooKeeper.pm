package ZooKeeper;
use ZooKeeper::XS;
use Carp;
use Moo;

has hosts => (
    is       => 'ro',
    required => 1,
);

has timeout => (
    is      => 'ro',
    default => 10 * 10**3,
);

has client_id => (
    is => 'ro',
);

has watcher => (
    is => 'ro',
);

sub _parse_host {
    my ($self, $host) = @_;
    return unless $host;
    croak "$host was not a valid hostname: expected \$hostname:\$port"
        unless $host =~ /[:\w]+:\d+/;
    return $host;
}

sub BUILDARGS {
    my ($class, %args) = @_;
    my @hosts;
    
    push @hosts, $class->_parse_host(delete $args{host});
    push @hosts, map {$class->_parse_host($_)} @{delete($args{hosts})||[]};
    $args{hosts} = \@hosts;

    return \%args;
}

sub BUILD {
    my ($self) = @_;
    my $hosts = join ',', @{$self->hosts||[]};
    $self->_xs_init($hosts);
}

1;
