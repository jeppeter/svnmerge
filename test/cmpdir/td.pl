#! perl

use warnings;
use strict;
use File::Basename;
use Cwd;

my ($d) = shift @ARGV;

sub MakeDirOrDie($)
{
	my ($d) = @_;
	my ($fd);
	if ( -d $d)
	{
		return ;
	}
	if ( -e $d )
	{
		die "($d) not dir";
	}

	$fd = dirname($d);
	print "($d) ($fd)\n";
	if ( $fd ne $d )
	{
		MakeDirOrDie($fd);
	}
	
	mkdir $d;
	if ($!)
	{
		die "can not mkdir($d) error($!)\n";
	}
	return;
}
eval( MakeDirOrDie($d));
if ($!)
{
	print STDERR "error $d($!)\n";
}
