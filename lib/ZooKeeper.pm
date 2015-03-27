package ZooKeeper;
use ZooKeeper::XS;
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

has buffer_length => (
    is      => 'ro',
    default => 2048,
);

has dispatcher_type => (
    is       => 'ro',
    init_arg => 'dispatcher',
    default  => sub { $ENV{PERL_ZOOKEEPER_DISPATCHER} || 'AnyEvent' },
);

has dispatcher => (
    is       => 'rw',
    init_arg => undef,
    handles  => [qw(create_watcher wait)],
);

sub _build_dispatcher {
    my ($self) = @_;
    my $type  = lc $self->dispatcher_type;
    my $class = $type eq 'anyevent'  ? 'ZooKeeper::Dispatcher::AnyEvent'
              : $type eq 'interrupt' ? 'ZooKeeper::Dispatcher::Interrupt'
              : croak "Unrecognized dispatcher type: $type";

    unless (eval "require $class; 1") {
        croak "Could not require dispatcher class $class: $@";
    }

    return $class->new;
}

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
    my ($self, $args) = @_;
    $self->dispatcher($self->_build_dispatcher);
    my $default_watcher = $self->watcher ? $self->create_watcher('' => $self->watcher, type => 'default') : undef;

    my $hosts = join ',', @{$self->hosts||[]};
    $self->_xs_init($hosts, $self->timeout, $default_watcher, $args->{client_id});

    $self->add_auth(%{$self->authentication}) if $self->authentication;
}

around create => sub {
    my ($orig, $self, $path, $value, %extra) = @_;
    return $self->$orig($path, $value, $extra{buffer_length}//$self->buffer_length, $extra{acl}, $extra{flags}//0);
};

around add_auth => sub {
    my ($orig, $self, $scheme, $credentials, %extra) = @_;
    $credentials = sha1_base64($credentials) if $scheme eq 'digest';
    my $watcher = $extra{watcher} ? $self->create_watcher('', $extra{watcher}, type => 'add_auth') : undef;
    return $self->$orig($scheme, $credentials, $watcher);
};

around delete => sub {
    my ($orig, $self, $path, %extra) = @_;
    return $self->$orig($path, $extra{version}//-1);
};

around exists => sub {
    my ($orig, $self, $path, %extra) = @_;
    my $watcher = $extra{watcher} ? $self->create_watcher($path, $extra{watcher}, type => 'exists') : undef;
    return $self->$orig($path, $watcher);
};

around get_children => sub {
    my ($orig, $self, $path, %extra) = @_;
    my $watcher = $extra{watcher} ? $self->create_watcher($path, $extra{watcher}, type => 'get_children') : undef;
    return $self->$orig($path, $watcher);
};

around get => sub {
    my ($orig, $self, $path, %extra) = @_;
    my $watcher = $extra{watcher} ? $self->create_watcher($path, $extra{watcher}, type => 'get') : undef;
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
