use strict;
use warnings;
use inc::Module::Install;

name 'ZooKeeper';
version '0.0.1';
license 'Perl_5';

cc_assert_lib {header => 'zookeeper/zookeeper_version.h', lib => '-lzookeeper_mt'};

use_ppport;
cc_include_paths 'include';
cc_libs '-lzookeeper_mt', '-lpthread';
cc_src_paths 'src';

clean_files 'MANIFEST', 'META.*';

cpanfile;
WriteAll;
