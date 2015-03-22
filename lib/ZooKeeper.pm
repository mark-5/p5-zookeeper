package ZooKeeper;
use ZooKeeper::XS;
use ZooKeeper::Watcher;
use Digest::SHA qw(sha1_base64);
use Carp;
use Moo;
use 5.10.1;

our $VERSION = '0.0.1';

has hosts => (
    is       => 'ro',
    required => 1,
);

has timeout => (
    is      => 'ro',
    default => 10 * 10**3,
);

has watcher => (
    is => 'ro',
);

has authentication => (
    is => 'ro',
);

has watchers => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { {} },
);

has buffer_length => (
    is      => 'ro',
    default => 2048,
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

    $args{watcher} &&= ZooKeeper::Watcher->new(cb => $args{watcher});

    return \%args;
}

sub BUILD {
    my ($self, $args) = @_;
    my $hosts = join ',', @{$self->hosts||[]};
    $self->_xs_init($hosts, $self->timeout, $self->watcher, $args->{client_id});
    $self->add_auth(%{$self->authentication}) if $self->authentication;
}

around create => sub {
    my ($orig, $self, $path, $value, %extra) = @_;
    return $self->$orig($path, $value, $extra{buffer_length}//$self->buffer_length, $extra{acl});
};

around add_auth => sub {
    my ($orig, $self, $scheme, $credentials) = @_;
    $credentials = sha1_base64($credentials) if $scheme eq 'digest';
    return $self->$orig($scheme, $credentials);
};

around delete => sub {
    my ($orig, $self, $path, %extra) = @_;
    return $self->$orig($path, $extra{version}//-1);
};

around exists => sub {
    my ($orig, $self, $path, %extra) = @_;
    my $watcher; if (my $cb = $extra{watcher}) {
        $watcher = ZooKeeper::Watcher->new(cb => $cb);
        $self->watchers->{$path}{exists}{$watcher} = $watcher;
    }
    return $self->$orig($path, $watcher);
};

around get_children => sub {
    my ($orig, $self, $path, %extra) = @_;
    my $watcher; if (my $cb = $extra{watcher}) {
        $watcher = ZooKeeper::Watcher->new(cb => $cb);
        $self->watchers->{$path}{get_children}{$watcher} = $watcher;
    }
    return $self->$orig($path, $watcher);
};

around get => sub {
    my ($orig, $self, $path, %extra) = @_;
    my $watcher; if (my $cb = $extra{watcher}) {
        $watcher = ZooKeeper::Watcher->new(cb => $cb);
        $self->watchers->{$path}{get}{$watcher} = $watcher;
    }
    return $self->$orig($path, $extra{buffer_length}//$self->buffer_length, $watcher);
};

around set => sub {
    my ($orig, $self, $path, $value, %extra) = @_;
    return $self->$orig($path, $value, $extra{version}//-1);
};

around set_acl => sub {
    my ($orig, $self, $path, $acl, %extra) = @_;
    return $self->$orig($path, $acl, $extra{version}//-1);
};

=head1 NAME

ZooKeeper - Perl bindings for Apache ZooKeeper

=head1 AUTHOR

Mark Flickinger <maf@cpan.org>

=head1 LICENSE

This software is licensed under the same terms as Perl itself.

=cut

1;
