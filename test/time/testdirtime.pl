#! perl -w




#################################
#
#   this file is to test DirTime.pm for it 
#
#################################



use Cwd qw( abs_path getcwd);
use File::Basename;
use Text::Diff;


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

use RandDir;


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

sub SetNewRandom($$$$$$$)
{
	my ($rc,$dira,$dirb,$equals,$notequals)=@_;

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

	$i = 0;
	$j = 0;

	while( ($i < @asortfiles) && ($j < @bsortfiles))
	{
		# now to give the compare
		if ( "$asortfiles[$i]" lt "$bsortfiles[$j]" )
		{
			$outstr .= "+ $asortfiles[$i]\n";
			$i ++;			
		}
		elsif ( "$asortfiles[$i]" gt "$bsortfiles[$j]" )
		{
			$outstr .= "- $bsortfiles[$j]\n";
			$j ++;
		}
		else
		{
			# that is the same,so we get the time
			$curaf = $asortfiles[$i];
			$curbf = $bsortfiles[$j];

			if ( $afiles{$curaf} > $bfiles{$curbf} )
			{
				$outstr .= "Y $curaf\n";
				$outstr .= "T $afiles{$curaf}\n";
			}
			elsif ($afiles{$curaf} < $bfiles{$curbf} )
			{
				$outstr .= "O $curbf\n";
				$outstr .= "T $bfiles{$curbf}\n";
			}
			$i ++;
			$j ++;
		}
	}
	
	while($i < @asortfiles)
	{
		$outstr .= "+ $asortfiles[$i]\n";
		$i ++;
	}

	while($j < @bsortfiles)
	{
		$outstr .= "- $bsortfiles[$j]\n";
		$j ++;
	}


	# now we return it
	return $outstr;
}


my (@filters,@rawfiles);

sub DirFilter
{
    my ($curfile)=$_;
    my ($ret);
    $ret = 0;
    foreach (@filters)
    {
        my($curfilter)=$_;
        if ($File::Find::name =~ m/$curfilter/)
        {
            $ret = 1;
            last;
        }
    }
    if ($ret == 0)
    {
        if ( (-f $File::Find::name) || ( -d $File::Find::name ))
        {
            push(@rawfiles,$File::Find::name);
        }
    }
}


sub CallDirTimePm($$@)
{
	my ($adir,$bdir,@_filters)=@_;
	my (@asorfiles,@bsorfiles);

	undef (@rawfiles);
	
}


sub Usage()
{
    my($exitcode)=shift @_;
    my ($msg)=shift @_;
    my($pkg,$fn,$ln,$s)=caller(0);
    my ($fp)=STDERR;

	if ($exitcode == 0)
	{
		$fp = STDOUT;
	}
    if(defined($msg))
    {
        printf $fp "[%-10s][%-20s][%-5d][INFO]:%s\n",$fn,$s,$ln,$msg;
    }

    print $fp "$0 dir times\n";
    exit($exitcode);
}

if (@ARGV < 2)
{
	Usage(3);
}

my ($testdir)=shift @ARGV;
my ($times)=shift @ARGV;
my ($i);
my ($adir,$bdir);

$adir = "$testdir/a";
$bdir = "$testdir/b";

for ($i=0;$i < $times;$i++)
{
	my ($foutstr,$eoutstr);
	my ($rc);
	my ($cmd,$fh,%afiles,%bfiles);
	my (@sorta,@sortb);
	# first to remove the dir
	remove_tree($adir);
	remove_tree($bdir);

	make_path($adir);
	make_path($bdir);

	$rc = TA->new();
	@afiles=();
	@bfiles=();
	# now to make the 
	$ret = SetNewRandom($rc,$adir,100,20,\%afiles);
	if ($ret < 0)
	{
		ErrorExit(4,"can not set randoma($i) $adir");
	}

	$ret = SetNewRandom($rc,$bdir,100,20,\%bfiles);
	if ($ret < 0)
	{
		ErrorExit(4,"can not set randomb($i) $bdir");
	}
		
	$cmd = "perl ../../dirtime.pl -t $adir | perl ../../dirtime.pl -f - -t $bdir";

	open($fh,"$cmd |") || ErrorExit(4,"can not runcmd $cmd");

	$eoutstr = "";
	while(<$fh>)
	{
		$eoutstr .= $_;
	}

	close($fh);
	if ( "$eoutstr"  ne "$foutstr")
	{
		ErrorExit(4,"String at $adir <=> $bdir\nfoutstr ==============\n$foutstr\n===============\neoutstr ++++++++++++++++++++++\n$eoutstr\n++++++++++++++++++\n");
	}	
}


