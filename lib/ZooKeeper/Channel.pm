package ZooKeeper::Channel;
use ZooKeeper::XS;
use Moo;

sub BUILD { shift->_xs_init }

1;
