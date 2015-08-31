use strict;
use warnings;
use inc::Module::Install;
use version 0.77;
use Config;
use File::Temp;
use IO::File;

all_from 'lib/ZooKeeper.pm';
readme_pod_from 'lib/ZooKeeper.pm';

homepage   'https://github.com/mark-5/p5-zookeeper';
bugtracker 'https://github.com/mark-5/p5-zookeeper/issues';
repository 'https://github.com/mark-5/p5-zookeeper.git';

cc_assert_lib header => 'zookeeper/zookeeper.h', lib => 'zookeeper_mt';

if (get_zk_version() >= '3.4.0') {
    cc_define '-DHAVE_ZOOKEEPER_3_4_0';
}

use_ppport;
cc_include_paths 'include';
cc_libs '-lzookeeper_mt', '-lpthread';
cc_src_paths 'src';

author_tests('xt');

cpanfile;
clean_files 'META.*';
WriteAll;


sub get_zk_version {
    my $dir = File::Temp->newdir;

    my $src = "$dir/check_zk_version.c";
    my $c   = IO::File->new($src, 'w');
    print $c <<'__END_C__';
#include <stdio.h>
#include <zookeeper/zookeeper_version.h>

int main() {
  printf("%d.%d.%d", ZOO_MAJOR_VERSION, ZOO_MINOR_VERSION, ZOO_PATCH_VERSION);
  return 0;
}
__END_C__
    close $c;

    my $bin = "$dir/check_zk_version";
    my $out = qx($Config{cc} -o $bin $src 2>&1);

    if ($?) {
        die "Could not determine ZooKeeper version:\n\n$out\n";
    }

    my $version_str = qx($bin);
    if ($?) {
        die "Could not determine ZooKeeper version:\n\n$version_str\n";
    }
    my $version_obj = version::parse('version', $version_str);
}
