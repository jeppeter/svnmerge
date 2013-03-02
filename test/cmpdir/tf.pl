#! perl -w

use warnings;
use strict;
use File::Copy;


sub CopyFileSafe($$)
{
	my ($s,$d)=@_;

	if ( -e $d && 
		! -f $d)
		{
			die "$d not regular file";
		}

	eval{copy ($s,$d);} || die "could not copy $s =>$d ($@)";
	return ;
}

my ($src,$dst)=@ARGV;
CopyFileSafe($src,$dst);

