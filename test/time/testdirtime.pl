#! perl -w




#################################
#
#   this file is to test DirTime.pm for it 
#
#################################


use strict;
use Cwd qw( abs_path getcwd);
use File::Basename;
use Text::Diff;
use File::Path qw(make_path remove_tree);
use File::Copy::Recursive qw(dircopy);

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
	my ($fp)=*STDERR;

	if ($exitcode==0)
	{
		$fp = *STDOUT;
	}
	elsif (defined($str))
	{
		print $fp "$str\n";
	}

	print $fp "$0 dir to test for the DirTime.pm\n";
	exit $exitcode;
}


sub ChangeFileContent($$)
{
	my ($file,$content)=@_;
	my ($fh);

	open($fh,">$file") || die "could not open $file for write";

	print $fh "$content";
	close($fh);

	return 0;	
}


sub __RandomDirCallBack($$$@)
{
	my ($dir,$fn,$p,@args)=@_;
	my ($rnd,$href,$cref)=@args;
	my ($mtime,$con);
	

	# now to set the time
	$con = $rnd->GetRandomFileName(30);
	ChangeFileContent($fn,$con);
	$mtime = time();
	utime $mtime,$mtime,$fn;
	$href->{$p} = $mtime;
	$cref->{$p} = $con;
	return 0;
}

sub SetNewRandom($$$$)
{
	my ($dir,$nums,$href,$cref)=@_;
	my ($ret);
	my ($rd,$rnd);

	$rd = RandDir->new();
	$rnd = Random->new();

	$rd->SetCallBack(\&__RandomDirCallBack,$rnd,$href,$cref);
	$ret = $rd->MakeRandomdirs($dir,$nums);
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
	my (%afiles,%bfiles,%acons,%bcons);
	my (@asort,@bsort,@samesort);
	my ($rnd,$ret,$i,$j);

	@asort = ();
	@bsort = ();
	undef(%afiles);
	undef(%bfiles);
	$rnd = Random->new();
	

	$ret = SetNewRandom($adir,$equals,\%afiles,\%acons);
	if ($ret < 0)
	{
		ErrorExit(4,"can not create random equal $adir");
	}

	dircopy($adir,$bdir);
	%bfiles = %afiles;
	%bcons = %acons;

	@samesort = sort(keys %afiles);
	# now we should make the time different
	for ($i=0;$i<@samesort;$i++)
	{
		my ($isyoung,$af,$bf,$curf,$mtime,$iscon,$newcon);
		$isyoung = $rnd->GetRandom(2);
		$iscon = $rnd->GetRandom(2);
		$curf = $samesort[$i];
		$af = "$adir/$curf";
		$bf = "$bdir/$curf";

		
		
		if ($isyoung)
		{
			if ($iscon)
			{
				$newcon = $rnd->GetRandomFileName(30);
				ChangeFileContent($bf,$newcon);
				$bcons{$curf} = $newcon;
			}
			$mtime = time;
			utime $mtime,$mtime,$af;
			$afiles{$curf} = $mtime;
			$mtime += 10;
			utime $mtime,$mtime,$bf;
			$bfiles{$curf} = $mtime;
		}
		else
		{
			$mtime = time;
			utime $mtime,$mtime,$bf;
			$bfiles{$curf}=$mtime;
			$mtime += 10;
			utime $mtime,$mtime,$af;
			$afiles{$curf} = $mtime;
		}
	}


	$ret = SetNewRandom($adir,$notequals,\%afiles,\%acons);
	if ($ret < 0)
	{
		ErrorExit(4, "can not create randoma diff $adir");
	}


	$ret = SetNewRandom($bdir,$notequals,\%bfiles,\%bcons);
	if ($ret < 0)
	{
		ErrorExit(4, "can not create randomb diff $bdir");
	}

	@asort = ExpandArray(\%afiles);
	@bsort = ExpandArray(\%bfiles);

	$foutstr = "AS $bdir\n";
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
							if (defined($acons{$af}) &&
								defined($bcons{$bf}))
								{
									if ("$acons{$af}" ne "$bcons{$bf}")
									{
										# it means that we change the file content
										$foutstr .= "M $bf\n";
									}
								}
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
				elsif (((!defined($afiles{$af})) &&
					(!defined($bfiles{$bf}))))
				{
					# nothing to do
				}
				else
				{
					# it is really an error
					DebugString("make all");
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

	$foutstr .= "AE $bdir\n";

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

STDOUT->autoflush(1);

for ($i=0;$i < $times;$i++)
{
	my ($foutstr,$eoutstr,$cmd,$fh);
	# first to remove the dir
	
	remove_tree($adir);
	remove_tree($bdir);

	make_path($adir);
	make_path($bdir);

	$foutstr = MakeCompareTest($adir,$bdir,100,30);
	if (!defined($foutstr))
	{
		# it means that we should not let it go on
		next;
	}
		
	$cmd = "perl ../../dirtime.pl -t $adir | perl ../../dirtime.pl -f - -t $bdir | perl ../../dirtime.pl -s $adir | perl ../../dirtime.pl -d $bdir";

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
	if (($i%16)==0)
	{
		if ($i)
		{
			print  "\n";
		}
		printf  "0x%08x:\t",$i;
	}
	print  ".";

}

print STDERR "\n";
print STDERR "Run Test $i times succ\n";

