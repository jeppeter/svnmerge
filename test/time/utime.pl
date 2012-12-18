#! perl

if ($#ARGV < 1)
{
	print STDERR "$0 file mtime [to change file time of mtime]\n";
	exit 3;
}

while (@ARGV >= 2)
{
	my ($f,$mtime);
	my (@attr);
	$f = shift @ARGV;
	$mtime = shift @ARGV;

	@attr = stat($f);
	if (@attr > 0)
	{
		utime $mtime,$mtime,$f;
	}
	else
	{
		print "$f can not stat\n";
	}
}
