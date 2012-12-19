#! perl -w

sub DebugString($)
{
	my ($str) = @_;
	my ($pkg,$file,$line,$subroutine) =caller(0);

	print STDERR "In[$file:$line] $str";
}


sub RmDirOrFile($$)
{
	my ($svndir,$file)=@_;
	my ($filedel,$cmd,$ret);

	$filedel = $svndir."/".$file;
	$cmd = "rm -rf $filedel";
	DebugString("$cmd\n");
	system($cmd);
	$ret = 0;
	if ( -e "$filedel" )
	{
		$ret = -1;
	}
	return $ret;
}

my ($svndir,$file)=@ARGV;
my ($fh);

open($fh,"<$file" ) || die "can not open $file";

while(<$fh>)
{
	my($line)=$_;
	my ($ret);
	chomp($line);
	if ( $line =~ /^\+ /o)
	{
		$line =~ s/^\+ //;
		#DebugString("Remove $svndir/$line\n");
		$ret = RmDirOrFile($svndir,$line);
		if ($ret != 0)
		{
			DebugString("Remove $line error $ret\n");
		}
	}
}
close($fh);
