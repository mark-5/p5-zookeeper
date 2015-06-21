configure_requires 'Devel::CheckLib';

requires 'AnyEvent';
requires 'Carp';
requires 'Digest::SHA';
requires 'Module::Runtime';
requires 'Moo';
requires 'Scalar::Util';
requires 'Scope::Guard';
requires 'Throwable';
requires 'XSLoader';

feature 'async-interrupt', 'Async::Interrupt support' => sub {
    recommends 'Async::Interrupt';
};
feature 'io-async', 'IO::Async support' => sub {
    recommends 'IO::Async::Handle';
};
feature 'poe', 'POE support' => sub {
    recommends 'POE';
    recommends 'POE::Future';
};

author_requires 'Async::Interrupt';
author_requires 'Devel::CheckLib';
author_requires 'FindBin::libs';
author_requires 'IO::Async::Handle';
author_requires 'Module::Install::AuthorTests';
author_requires 'Module::Install::CPANfile';
author_requires 'Module::Install::ReadmePodFromPod';
author_requires 'Module::Install::XSUtil';
author_requires 'POE';
author_requires 'POE::Future';

test_requires 'AnyEvent::Future';
test_requires 'Test::Class::Moose', '0.55';
test_requires 'Test::LeakTrace';
test_requires 'Test::More';
test_requires 'Test::Pod';
test_requires 'Test::Strict';
test_requires 'Try::Tiny';
