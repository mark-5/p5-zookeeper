configure_requires 'Devel::CheckLib';
configure_requires 'Module::Install::CPANfile';
configure_requires 'Module::Install::XSUtil';

requires 'AnyEvent';
requires 'Async::Interrupt';
requires 'Carp';
requires 'Digest::SHA';
requires 'Moo';
requires 'Scalar::Util';
requires 'XSLoader';

test_requires 'Test::More';
test_requires 'Test::LeakTrace';
