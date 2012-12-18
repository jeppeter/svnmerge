#! perl

use Getopt::Std;
use vars qw ($opt_h $opt_f $opt_t $opt_v $opt_V);
use Cwd qw( abs_path getcwd);
use File::Basename;

sub GetScriptDir()
{
    my($script_dir);
    $script_dir = dirname(abs_path($0));
    return $script_dir;
}

BEGIN
{
	my ($script_dir)=GetScriptDir();
	push (@INC,$script_dir);
	
}

use DirTime;

sub ErrorExit
{
    my ($exitcode,$str)=@_;
    my ($package,$file,$line,$func)=caller(0);

    print STDERR "[$file][$func]:$line $str";
    exit($exitcode);
}
sub DebugString
{
    my ($str)=@_;
    my ($package,$file,$line,$func)=caller(0);

    print STDERR "[$file][$func]:$line $str";
}


# now to handle the time function
sub DirTimePrint($$$$@)
{
	my ($dir,$fname,$curd,$pname,@args)=@_;
	my ($relativefname,$tfname);
	my ($fh)=@args;
	my (@sts,$mtime);
	$tfname = $fname;
	$fname =~ s/^\Q$dir\E[\/\\]+//;

	$relativefname = $fname;
	if ( -d $tfname )
	{
		# if directory ,not give any of time
		print $fh  "F $relativefname\n";
	}
	elsif ( -f $tfname )
	{
		# only file to print time
		@sts = stat($tfname);
		if (@sts <= 0)
		{
			return -3;
		}

		# that is ok
		$mtime = $sts[9];
		print $fh "F $relativefname\n";
		print $fh "T $mtime\n";
	}	
	return 0;
}

sub ListDirTime($$@)
{
	my ($dir,$outfh,@filters)=@_;
	my ($ret);
	my ($fs);

	$fs = FindSort->new();
	$fs->SetDir($dir);
	$fs->SetFilters(@filters);
	print $outfh "TS $dir\n";
	$fs->SetCallBack(\&DirTimePrint,$outfh);
	$ret = $fs->ScanDirs($dir);
	print $outfh "TE $dir\n";
	return $ret;
}

sub DiffDirTime($$$@)
{
	my ($dir,$infh,$outfh,@filters)=@_;
	my ($dt);
	my ($cont);
	my ($file,$ftime);
	my ($lineno);
	
	# now to
	$dt = DirTime->new();
	$dt->SetFilters(@filters);
	$dt->SetDir($dir);
	$dt->StartScanDir($dir);
	#DebugString("infh $infh filters @filters\n");

	undef($file);
	undef($ftime);
	$lineno = 0;
	print $outfh "TS $dir\n";
	while(<$infh>)
	{
		my ($line)=$_;
		$lineno ++;
		chomp($line);
		#DebugString("$lineno:$line\n");
		if ($line =~ m/^F /o)
		{
			if(defined($file))
			{
				do
				{
					($str,$cont)=$dt->GetCmpString($file,undef);
					print $outfh "$str";
				}while($cont);
			}
			$line =~ s/^F //;
			$file = $line;
		}
		elsif ($line =~ m/^T /o)
		{
			if (!defined($file))
			{
				ErrorExit(4,"Need file at lineno($lineno)\n");;
			}
			$line =~ s/^T //;
			$ftime = $line;
		}
		elsif ($line =~ m/^TE /o)
		{
			last;
		}

		if (defined($ftime) && defined($file))
		{
			do
			{
				($str,$cont)=$dt->GetCmpString($file,$ftime);
				print $outfh "$str";
			}while($cont);

			undef($file);
			undef($ftime);
		}
	}
	do
	{
		($str,$cont)=$dt->GetCmpString(undef,undef);
		print $outfh "$str";
	}while($cont);
	
	$dt->DESTROY();
	undef($dt);
	print $outfh "TE $dir\n"; 

	return 0;
}

sub Usage
{
	my ($exitcode)= shift @_;
	my ($msg) = shift @_;
	my ($fh) = STDERR;

	if ($exitcode == 0)
	{
		$fh = STDOUT;
	}

	if (defined($msg))
	{
		print $fh "$msg\n";
	}

	print $fh "$0 [OPTIONS] [FILTERS]\n";
	print $fh "\t-h      :display this help message\n";
	print $fh "\t-v      :verbose mode\n";
	print $fh "\t-f file :to make the file - for stdin\n";
	print $fh "\t-t dir  : directory to specify\n";
	print $fh "\t-V      : display version\n";

	exit ($exitcode);
}

getopts("hf:t:vV");
my (@filters,$ret);

if (defined($opt_h))
{
	Usage(0);
}

if (defined($opt_V))
{
	print STDOUT "$0 version 0.0.1\n";
	exit (0);
}
@filters = @ARGV;

if (defined($opt_f) && defined($opt_t))
{
	my ($ifh);
	if ("$opt_f" eq "-")
	{
		$ifh = STDIN;
	}
	else
	{
		open($ifh,"<$opt_f") || ErrorExit(6,"can not open $opt_f $!");
	}
	#DebugString("opt_f($opt_f) opt_t($opt_t)\n");
	$ret = DiffDirTime($opt_t,$ifh,STDOUT,@filters);
	if (fileno($ifh) != fileno(STDIN))
	{
		close($ifh);
	}
	undef $ifh;
	if ($ret < 0)
	{
		ErrorExit(4,"can not compare with ($opt_f) dir($opt_t)");
	}
	
}
elsif (defined($opt_t))
{
	$ret = ListDirTime($opt_t,STDOUT,@filters);
	if ($ret < 0)
	{
		ErrorExit(5,"can not list ($opt_t)");
	}
}
else
{
	Usage(3,"must specify the directory used -t");
}

