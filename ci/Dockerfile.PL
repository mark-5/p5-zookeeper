#!/usr/bin/env perl
use strict;
use warnings;
use IO::File;
my $path = substr($0, 0, -3);

my @missing = grep { not exists $ENV{$_} } qw(
    ZOOKEEPER_VERSION
    PERL_VERSION
);
if (@missing) {
    my $msg = "Missing required env vars:\n";
    $msg   .= "  $_\n" for @missing;
    die "$msg\n";
}

my $zookeeper_version = $ENV{ZOOKEEPER_VERSION};
my $perl_version      = $ENV{PERL_VERSION};
my $perl_flags        = $ENV{PERL_THREADS} ? '--thread' : '';

my @system_packages = qw(
    autoconf
    automake
    curl
    libcppunit-dev
    libtool
    openjdk-7-jre
);

my $file = IO::File->new($path, 'w')
    or die "cannot open $path for writing: !";
print $file <<"__END__";

FROM perl:$perl_version

RUN apt-get -q -y update && \\
	apt-get -q -y install @system_packages

RUN mkdir -p /opt && \\
	curl -L http://apache.mirrors.pair.com/zookeeper/zookeeper-$zookeeper_version/zookeeper-$zookeeper_version.tar.gz | tar -C /opt -zxf - && \\
	mv /opt/zookeeper-$zookeeper_version /opt/zookeeper && \\
	cp /opt/zookeeper/conf/zoo_sample.cfg /opt/zookeeper/conf/zoo.cfg && \\
	mkdir -p /tmp/zookeeper
EXPOSE 2181 2888 3888

RUN cd /opt/zookeeper/src/c && \\
    autoreconf -if && \\
    ./configure && \\
    make install && \\
    ldconfig

WORKDIR /tmp/perl
COPY cpanfile .
RUN cpanm --quiet --notest --with-develop --with-all-features --installdeps .

WORKDIR /code
COPY . /code

__END__
