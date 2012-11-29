#! perl -w




#################################
#
#   this file is to test DirTime.pm for it 
#
#################################



use Cwd qw( abs_path getcwd);
use File::Basename;


sub GetScriptDir()
{
    my($script_dir);
    $script_dir = dirname(abs_path($0));
    return $script_dir;
}

sub GetScriptLibDir()
{
    my ($libdir);
    my ($libredir);
    $libredir = dirname(abs_path($0));
    $libredir .= "/../lib";
    $libdir= abs_path($libredir);
    return $libdir;
}

sub DebugString($)
{
    my($msg)=@_;
    my($pkg,$fn,$ln,$s)=caller(0);

    if(defined($st_Verbose)&&$st_Verbose)
    {
        printf STDERR "[%-10s][%-20s][%-5d][INFO]:%s\n",$fn,$s,$ln,$msg;
    }
}


BEGIN
{
	my ($script_dir)=GetScriptDir();
	push (@INC,$script_dir);
	$script_dir = GetScriptLibDir();
	push (@INC,$script_dir);
	
}

use Random;

sub Usage($)
{
	my ($exitcode)=shift @_;
	my ($str)=shift @_;
	my ($fp)=STDERR;

	if ($exitcode==0)
	{
		$fp = STDOUT;
	}
	elsif (defined($str))
	{
		print $fp "$str\n";
	}

	print $fp "$0 dir to test for the DirTime.pm\n";
	exit $exitcode;
}

sub ErrorExit($$)
{
	my ($exitcode,$msg)=@_;
    my($pkg,$fn,$ln,$s)=caller(0);
	

	print STDERR "$pkg[$fn:$ln]\t$msg\n";
	exit $exitcode;
}

if ($#ARGV < 0)
{
	Usage(3);
}

my ($dir)=shift @ARGV;
my ($dira,$dirb);

if ( ! -d $dir )
{
	ErrorExit(3,"$dir not directory");
}

