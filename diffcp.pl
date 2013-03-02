#! perl


use warnings;
use strict;
use File::Basename;
use File::Path;
use Cwd;
use File::Copy;
use Getopt::Std;
use vars qw ($opt_h $opt_o $opt_t $opt_f);
sub Usage
{
	my ($ec) = shift @_;
	my ($msg) = shift @_;
	my ($fp);
	$fp = *STDERR;
	if ($ec == 0)
	{
		$fp = *STDOUT;
	}

	if (defined($msg))
	{
		print $fp "$msg\n";
	}
	
	print $fp "$0 [OPTIONS] dir\n";
	print $fp "\t-o ourdir    our svn dir\n";
	print $fp "\t-t their     their svn dir\n";
	print $fp "\t-f difffile  diff file to compare\n";
	print $fp "\t\tdir is the compare dir\n";

	exit($ec);
}

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

sub CopyFileOrDir($$$)
{
	my ($srcdir,$dstdir,$f)=@_;
	my ($totalsrc,$totaldst,$sd,$dd,$sb,$db);

	$totalsrc = "$srcdir/$f";
	$totaldst = "$dstdir/$f";

	# first to test whether it is file ,or directory
	
	if ( -f $totalsrc )
	{
		$sd = dirname($totalsrc);
		$dd = dirname($totaldst);
		MakeDirOrDie($dd);
		# now we should copy it
		CopyFileSafe($totalsrc,$totaldst);
		
	}
	elsif ( -d $totalsrc )
	{
		MakeDirOrDie($totaldst);
	}
	else
	{
		return ;
	}
}

sub CopyDiffSvn($$$$)
{
	my ($od,$td,$df,$rd)=@_;
	my ($fh);
	my ($rod,$rtd);

	if (! -d $rd )
	{
		MakeDirOrDie($rd);
	}

	$rod = "$rd/ours";
	$rtd = "$rd/theirs";
	MakeDirOrDie($rod);
	MakeDirOrDie($rtd);

	open($fh ,"<$df") || die "could not open($df) error($!)";
	while(<$fh>)
	{
		my ($l) = $_;
		my ($f);
		chomp($l);
		undef($f);

		if ($l =~ m/^\+ /o )
		{
			$l =~ s/^\+ //;
			$f = $l;
		}
		elsif ($l =~ m/^- /o)
		{
			$l =~ s/^- //;
			$f = $l;
		}
		elsif ($l =~ m/^M /o)
		{
			$l =~ s/^M //;
			$f = $l;
		}
		else
		{
			next;
		}

		

		CopyFileOrDir($od,$rod,$f);
		CopyFileOrDir($td,$rtd,$f);
	}
	close($fh);
	return;
}

my ($od,$td);
my ($df,$rd);

getopts("ho:t:f:");

if (defined($opt_h))
{
	Usage(0);
}

if (!defined($opt_o))
{
	Usage(3,"must specify -o");
}
$od = $opt_o;

if (!defined($opt_t))
{
	Usage(3,"must specify -t");
}

$td = $opt_t;

if (!defined($opt_f))
{
	Usage(3,"must specify -f");
}
$df = $opt_f;

$rd = shift @ARGV;
if (!defined($rd))
{
	$rd = ".";
}


CopyDiffSvn($od,$td,$df,$rd);

