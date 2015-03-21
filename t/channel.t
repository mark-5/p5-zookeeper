use strict; use warnings;
use Test::More;
use Test::LeakTrace;
use_ok('ZooKeeper::Channel');
can_ok('ZooKeeper::Channel', 'new');
isa_ok(ZooKeeper::Channel->new, 'ZooKeeper::Channel');

my $channel = ZooKeeper::Channel->new;

my %data = (
    'undef'      => undef,
    'regex'      => qr/.*/,
    'glob'       => *STDIN,
    'glob-ref'   => \*STDIN,
    'int'        => 9,
    'int-ref'    => \42,
    'string'     => "a string",
    'string-ref' => \"a ref to a string",
    'array-ref'  => [],
    'hash-ref'   => {},
    'code-ref'   => sub {},
    'object'     => ZooKeeper::Channel->new,
);

while (my ($type, $datum) = each %data) {
    is($channel->recv, undef, "received undef on empty channel");

    $channel->send($datum);
    is($channel->recv, $datum, "sent and received single $type");
    is($channel->recv, undef, "received undef on empty channel after sending single $type");
    no_leaks_ok {
        $channel->send($datum);
        $channel->recv;
    } "no leaks sending and receiving single $type";

    my $repeat = int(rand(5)) + 1;
    $channel->send(($datum) x $repeat);
    my $match = grep {($channel->recv||'') eq ($datum||'')} 1 .. $repeat;
    is($match, $repeat, "sent and received multiple ${type}s");
    is($channel->recv, undef, "received undef on empty channel after sending multiple ${type}s");
    no_leaks_ok {
        $channel->send(($datum) x $repeat);
        $channel->recv for 1 .. $repeat;
    } "no leaks sending and receiving multiple ${type}s";
}

done_testing();
