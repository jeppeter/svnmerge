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

sub SetNewRandom($$$$$)
{
	my ($rc,$dira,$dirb,$equals,$notequals)=@_;
	my ($isdir,$isamtime);
	my ($cona,$conb,$i);
	my ($curf,$curaf,$curbf,$da,$db);

	# now first to make 
	for ($i=0;$i<$equals ; $i++)
	{
		$curf="";
		$curaf = "$dira/";
		$curbf = "$dirb/";
		$isdir = 0;
		do
		{
			$isdir = $rc->GetRandom(2);

			if ($isdir)
			{
				$curf .= $rc->GetRandomFileName(12);
				
			}
			else
			{
				$curf .= $rc->GetRandomFileName(12);
			}
		}while($isdir);

		$curaf .= $curf;
		$curbf .= $curf;

		if (length($curaf) > 200 || length($curbf) > 200)
		{
			# do not make length ok
			next;
		}

		$da = dirname($curaf);
		$db = dirname($curbf);

		if ( ! -e $da )
		{
			
		}
	}
	
}

