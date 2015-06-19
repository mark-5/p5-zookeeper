configure_requires 'Devel::CheckLib';
configure_requires 'Module::Install::CPANfile';
configure_requires 'Module::Install::ReadmePodFromPod';
configure_requires 'Module::Install::XSUtil';

requires 'Carp';
requires 'Digest::SHA';
requires 'Module::Runtime';
requires 'Moo';
requires 'Scalar::Util';
requires 'Throwable';
requires 'XSLoader';

feature 'anyevent', 'AnyEvent support' => sub {
    recommends 'AnyEvent';
};
feature 'async-interrupt', 'Async::Interrupt support' => sub {
    recommends 'AnyEvent';
    recommends 'Async::Interrupt';
};
feature 'io-async', 'IO::Async support' => sub {
    recommends 'IO::Async::Handle';
};

test_requires 'AnyEvent::Future';
test_requires 'Test::Class::Moose', '0.55';
test_requires 'Test::LeakTrace';
test_requires 'Test::More';
test_requires 'Test::Pod';
test_requires 'Test::Strict';
test_requires 'Try::Tiny';
