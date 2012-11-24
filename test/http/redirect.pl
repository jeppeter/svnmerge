#! perl -w

use Data::Dumper;
use IO::Handle;
sub DebugString($)
{
    my ($str)=@_;
    my ($package,$file,$line,$func)=caller(0);

    print STDERR "[$file][$func]:$line $str";
}


DebugString("\n");
my ($dumper);
my ($fh)=STDIN;
my ($f);

if (@ARGV > 0)
{
	$f = shift @ARGV;
	DebugString("Open $f\n");
	undef $fh;
	open($fh,"<$f") || die "can not open $f";
}

STDOUT->autoflush(1);
$fh->autoflush(1);
while(1)
{
    my ($con);
    my (@canread);
    DebugString("\n");
    $con = <$fh>;
    if (!defined($con))
    {
	    DebugString("\n");
        last;
    }
    DebugString("\n");
    chomp($con);
    print STDOUT "$con\n";
}

if (defined($f))
{	
	
	DebugString("Close $f fh ".fileno($fh)." STDIN ".fileno(STDIN)."\n");
	close($fh);
}
undef $fh;

DebugString("Exit\n");
