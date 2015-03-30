configure_requires 'Devel::CheckLib';
configure_requires 'Module::Install::CPANfile';
configure_requires 'Module::Install::ReadmePodFromPod';
configure_requires 'Module::Install::XSUtil';

requires 'AnyEvent';
requires 'Async::Interrupt';
requires 'Carp';
requires 'Digest::SHA';
requires 'Moo';
requires 'Scalar::Util';
requires 'Throwable';
requires 'XSLoader';

test_requires 'Test::Class::Moose', '0.55';
test_requires 'Test::More';
test_requires 'Test::LeakTrace';
test_requires 'Test::Pod';
test_requires 'Try::Tiny';
