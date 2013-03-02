#! perl

use warnings;
use strict;
use File::Path;
sub MakeDirOrDie($)
{
	my ($d) = @_;
	if ( -d $d)
	{
		return ;
	}
	if ( -e $d )
	{
		die "($d) not dir";
	}

	
	eval{mkpath($d)} || die "can not mkdir($d) error($@)\n";
	return;
}
$! =0;
my ($d) = shift @ARGV;

if (defined($d))
{
	eval{MakeDirOrDie($d);} || print STDERR "$@";
}
