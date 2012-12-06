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

sub ErrorExit($$)
{
	my ($exitcode,$msg)=@_;
    my($pkg,$fn,$ln,$s)=caller(0);

    printf STDERR "[%-10s][%-20s][%-5d][INFO]:%s\n",$fn,$s,$ln,$msg;
	exit ($exitcode);
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
	my (%afiles,%bfiles);
	my ($outstr);
	my (@asortfiles,@bsortfiles);

	# now first to make the things ok
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
			ErrorExit( 4,"could not make dir $da for $curaf");
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
			ErrorExit(4, "could not make dir $db for $curbf");
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
			ErrorExit(4, "can not stat $curaf");
		}
		$amtime = $fst[9];

		@fst = stat($curbf);
		if (@fst <= 9)
		{
			ErrorExit(4, "can not stat $curbf");
		}

		$bmtime = $fst[9];

		$smtime = $amtime;
		if ($bmtime > $amtime)
		{
			$smtime = $bmtime;
		}

		utime $smtime,$smtime,$curaf || ErrorExit(4 ,"can not change file $curaf");
		utime $smtime,$smtime,$curbf || ErrorExit(4, "can not change file $curbf");

		# ok nothing to handle for this
	}

	# now to make the not equals ok
	for ($i=0;$i<$notequals;$i++)
	{
		$curf = "";
		$curaf = "$dira/";
		$curbf = "$dirb/";
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

		$curaf .= "$curf";

		$curf = "";
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

		$curbf .= "$curf";

		# now if the file is ok
		if (length($curaf) < 200)
		{
			$da = dirname($curaf);
			if ( ! -e $da ||  ! -d $da )
			{
				remove_tree($da);
				make_path($da);
			}

			if ( ! -d $da )
			{
				ErrorExit(4, "could not make dir $da for $curaf");
			}

			# and touch the file
			if ( ! -e $curaf || ! -f $curaf )
			{
				remove($curaf);
				touch($curaf);
			}

			@fst = stat($curaf);
			if (@fst <= 9)
			{
				ErrorExit(4, "can not stat $curaf");
			}
			$amtime = $fst[9];
			$afiles{$curaf} = $amtime;			
		}

		if (length($curbf) < 200)
		{
			$db = dirname($curbf);
			if ( ! -e $db ||  ! -d $db )
			{
				remove_tree($db);
				make_path($db);
			}

			if ( ! -d $db )
			{
				ErrorExit(4, "could not make dir $db for $curbf");
			}

			# and touch the file
			if ( ! -e $curbf || ! -f $curbf )
			{
				remove($curbf);
				touch($curbf);
			}

			@fst = stat($curbf);
			if (@fst <= 9)
			{
				ErrorExit(4, "can not stat $curbf");
			}
			$bmtime = $fst[9];
			$bfiles{$curbf} = $bmtime;			
			
		}		
	}
	
	@asortfiles = sort(keys %afiles);
	@bsortfiles = sort(keys %bfiles);

	$outstr = "";
	
	
}

