#! perl -w

use HTTP::Server::Brick;
use HTTP::Status;

if (@ARGV < 2)
{
	print STDERR "$0 rootdir port\n";
	exit (3);
}

my ($rootdir)=shift @ARGV;
my ($port)=shift @ARGV;

my ($brick);

$brick= HTTP::Server::Brick->new( port => $port);

$brick->mount('/' => {path => "$rootdir"});

$brick->start;

