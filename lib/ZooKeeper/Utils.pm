package ZooKeeper::Utils;
use strict; use warnings;
use version 0.77;
use Carp qw(croak);
use ZooKeeper::Constants qw(ZOOKEEPER_VERSION);
use parent 'Exporter';
our @EXPORT = qw(assert_zookeeper_version);
our @EXPORT_OK = @EXPORT;

sub assert_zookeeper_version {
    my ($version, $msg) = @_;
    my $have = version::parse('version', ZOOKEEPER_VERSION);
    if ($have < $version) {
        $msg =~ s/\b(%v)\b/$have/;
        croak $msg;
    }
}

1;
