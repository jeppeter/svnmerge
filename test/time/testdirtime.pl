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
	my ($amtime,$bmtime,@fst,$smtime);
	my (@afiles,@bfiles);

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
				$curf .= "/".$rc->GetRandomFileName(12);
				
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

		if ( ! -e $da ||  ! -d $da )
		{
			remove_tree($da);
			make_path($da);
		}

		if ( ! -d $da )
		{
			die "could not make dir $da for $curaf\n";
		}

		if ( ! -e $curaf || ! -f $curaf )
		{
			remove($curaf);
			touch($curaf);
		}

		if ( ! -e $db || ! -d $db )
		{
			remove_tree($db);
			make_path($db);
		}

		if ( ! -d $db )
		{
			die "could not make dir $db for $curbf\n";
		}

		if ( ! -e $curbf || ! -f $curbf )
		{
			remove($curbf);
			touch($curbf);
		}

		# now to utime
		@fst = stat($curaf);
		if (@fst <= 9)
		{
			die "can not stat $curaf\n";
		}
		$amtime = $fst[9];

		@fst = stat($curbf);
		if (@fst <= 9)
		{
			die "can not stat $curbf\n";
		}

		$bmtime = $fst[9];

		$smtime = $amtime;
		if ($bmtime > $amtime)
		{
			$smtime = $bmtime;
		}

		utime $smtime,$smtime,$curaf || die "can not change file $curaf\n";
		utime $smtime,$smtime,$curbf || die "can not change file $curbf\n";

		# ok nothing to handle for this
	}

	
	
}

