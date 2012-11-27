#! perl

# this perl script compare the time of the function and 

if ($#ARGV < 0)
{
	print STDERR "$0 <files> [print file times]\n";
	exit 3;
}

foreach(@ARGV)
{
	my ($f)=$_;
	my ($atime,$mtime,$ctime);
	my (@attr);
	undef @attr;
	@attr = stat($f);
	if (@attr > 0)
	{
		$atime = $attr[8];
		$mtime = $attr[9];
		$ctime = $attr[10];
		print "$f atime $atime mtime $mtime ctime $ctime\n";
	}
	else
	{
		print "$f can not stat\n";
	}
	
}
