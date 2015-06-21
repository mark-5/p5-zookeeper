package ZooKeeper::XT::Utils;
use strict; use warnings;
use Try::Tiny;
use parent 'Exporter';
our @EXPORT = qw(test_hosts timeout);
our @EXPORT_OK = @EXPORT;

sub test_hosts {
    $ENV{ZOOKEEPER_TEST_HOSTS} // 'localhost:2181';
}

sub timeout {
    my ($time, $code) = @_;
    my $timeout = "TIMEOUT\n";

    my $timedout = try {
        local $SIG{ALRM} = sub { die $timeout };
        alarm($time);
        $code->();
        alarm(0);
    } catch {
        die $_ unless $_ eq $timeout;
    };
    alarm(0);
}

1;
