#! perl -w

use Getopt::Std;
use vars qw ($opt_h $opt_s $opt_d);

sub Usage($)
{
	my ($ec) = @_;
	my ($fp);
	$fp = STDERR;
	if ($ec == 0)
	{
		$fp = STDOUT;
	}
	print $fp "dircmp [OPTIONS] \@filters\n";
	print $fp "-d dest\n";
	print $fp "-s src\n";

	exit($ec);
}
sub DebugString($)
{
    my ($str)=@_;
    my ($package,$file,$line,$func)=caller(0);

    print STDERR "[$file][$func]:$line $str";
}

getopts("hs:d:");

if (!defined($opt_s) || !defined($opt_d))
{
	Usage(3);
}

if (defined($opt_h))
{
	Usage(0);
}

my (@filters) = $#ARGV >= 0 ?  @ARGV : ();
my ($cmd,$ret);

$cmd = " perl dirsha.pl \"$opt_d\" ";

if ( $#filters >= 0 )
{
	$cmd .= join(" ",@filters);
}

$cmd .= " | perl dirsha.pl -f - \"$opt_s\" ";

if ( $#filters >= 0)
{
	$cmd .= join(" ",@filters);
}

$ret = system($cmd);
DebugString("run cmd $cmd ".($ret == 0 ? "Succ" : "Failed $ret")."\n");


