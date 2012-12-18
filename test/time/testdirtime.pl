#! perl -w




#################################
#
#   this file is to test DirTime.pm for it 
#
#################################



use Cwd qw( abs_path getcwd);
use File::Basename;
use Text::Diff;
use File::Path qw(make_path remove_tree);


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

    printf STDERR "[%-10s][%-20s][%-5d][ERROR]:%s\n",$fn,$s,$ln,$msg;
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


sub Usage
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



sub __RandomDirCallBack($$$@)
{
	my ($dir,$fn,$p,@args)=@_;
	my ($rnd,$href)=@args;
	my ($mtime);

	# now to set the time
	$mtime = $rnd->GetRandom(1000000000);
	utime $mtime,$mtime,$fn;
	$href->{$p} = $mtime;
	return 0;
}

sub SetNewRandom($$$$)
{
	my ($dir,$equals,$notequals,$href)=@_;
	my ($ret);
	my ($rd,$rnd);

	$rd = RandDir->new();
	$rnd = Random->new();

	$rd->SetCallBack(\&__RandomDirCallBack,$rnd,$href);
	$ret = $rd->MakeRandomdirs($dir,$equals);
	if ($ret != 0)
	{
		return $ret;
	}

	$ret = $rd->MakeRandomdirs($dir,$notequals);
	if ($ret != 0)
	{
		return $ret;
	}

	# all is ok
	return 0;

}

sub ExpandArray($)
{
	my ($href)=@_;
	my (@sortarr);
	my (@retarr,$curf,$i,$j);

	@sortarr = sort keys(%{$href});

	# now we should give the expand
	for($i=0;$i<@sortarr;$i++)
	{
		my (@ns,$fn);
		$curf = $sortarr[$i];
		@ns = split('/',$curf);
		$fn = "";
		for ($j=0;$j<(scalar(@ns)-1);$j++)
		{
			$fn .= "$ns[$j]";
			if (!defined($href->{$fn}))
			{
				push(@retarr,$fn);
			}
			
			$fn .= "/";
		}

		# that the last one ,so we should push it ok
		push(@retarr,$curf);
	}

	@sortarr = sort(@retarr);
	@retarr = @sortarr;

	return @retarr;
	
}




sub MakeCompareTest($$$$)
{
	my ($adir,$bdir,$equals,$notequals)=@_;
	my ($foutstr);
	my (%afiles,%bfiles);
	my (@asort,@bsort);
	my ($rc);

	undef(%afiles);
	undef(%bfiles);
	@asort = ();
	@bsort = ();
	undef(%afiles);
	undef(%bfiles);


	$ret = SetNewRandom($adir,$equals,$notequals,\%afiles);
	if ($ret < 0)
	{
		ErrorExit(4,"can not create randoma $adir");
	}

	$ret = SetNewRandom($bdir,$equals,$notequals,\%bfiles);
	if ($ret < 0)
	{
		ErrorExit(4, "can not create randomb $bdir");
	}

	@asort = ExpandArray(\%afiles);
	@bsort = ExpandArray(\%bfiles);

	$foutstr = "TS $bdir\n";
	for ($i=0,$j=0;$i<@asort && $j < @bsort;)
	{
		my ($af,$bf);
		$af = $asort[$i];
		$bf = $bsort[$j];
		if ("$af" lt "$bf" )
		{
			$foutstr .= "- $af\n";
			$i ++;
		}
		elsif ( "$af" gt "$bf")
		{
			$foutstr .= "+ $bf\n";
			$j ++;
		}
		else		
		{
			my ($atime,$btime);
			if (defined($afiles{$af}) &&
				defined($bfiles{$bf}))
				{
					$atime = $afiles{$af};
					$btime = $bfiles{$bf};
					if ( $atime == 0 || 
						$btime == 0)
						{
							# nothing to do
						}
						elsif ($atime < $btime)
						{
							$foutstr .= "Y $bf\n";
						}
						elsif ($atime > $btime)
						{
							# nothing to do
						}
						else
						{
							# it is ok
						}
				}
				elsif (defined($afiles{$af}) &&
					defined($bfiles{$bf}))
				{
					# nothing to do
				}
				else
				{
					# it is really an error
					return undef;
				}
				$i ++;
				$j ++;
		}
	}

	for ( ;$i<@asort;$i++)
	{
		my ($af);
		$af = $asort[$i];
		$foutstr .= "- $af\n";
	}

	for (;$j<@bsort;$j++)
	{
		my ($bf);
		$bf = $bsort[$j];
		$foutstr .= "+ $bf\n";
	}

	$foutstr .= "TE $bdir\n";

	return $foutstr;
	
}

if (@ARGV < 2)
{
	Usage(3,"\@ARGV @ARGV < 2");
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
	# first to remove the dir
	if (($i%10)==0)
	{
		if ($i)
		{
			print  "\n";
		}
		printf  "0x%08x:\t",$i;
	}
	print  "."; 
	
	remove_tree($adir);
	remove_tree($bdir);

	make_path($adir);
	make_path($bdir);

	$foutstr = MakeCompareTest($adir,$bdir,100,20);
	if (!defined($foutstr))
	{
		# it means that we should not let it go on
		next;
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

print STDERR "\n";
print STDERR "Run Test $i times succ\n";

