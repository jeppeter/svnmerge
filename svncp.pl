#! perl -w

use File::Basename;
use Cwd;

sub DebugString($)
{
	my ($str) = @_;
	my ($pkg,$file,$line,$subroutine) =caller(0);

	print STDERR "In[$file:$line] $str";
	#print STDOUT "$str";
}


sub AddSvn($$$$)
{
	my ($todir,$fromdir,$file,$test) = @_;
	my ($tofile,$fromfile);
	my ($todirname);
	my (@cmd,$ret);
	my ($olddir,$tmpdir);
	$tofile = $todir."/".$file;
	$fromfile = $fromdir."/".$file;

	
	if ( $test != 0)
	{
		if ( ! -f $tofile )
		{
			
			DebugString("$tofile not exist\n");
			return -1;
		}
	}

	#
	$olddir = getcwd();
	if ( ! chdir $todir  )
	{
		DebugString("Can not change to $todir\n");
		return -1;
	}

	$tmpdir = getcwd();
	#DebugString("Cur Dir $tmpdir\n");
	

	@cmd = ("svn","add",$file);
	DebugString("@cmd\n");
	if ($test != 0)
	{
		$ret = system(@cmd);
		if ( $ret != 0)
		{
			chdir ($olddir);
			DebugString("Failed\n");
			return -1;
		}
	}

	chdir($olddir);

	return 0;
}



sub CopyFile($$$$)
{
	my ($fromdir,$todir,$file,$test) = @_;
	my ($tofile,$fromfile);
	my ($todirname);
	my (@cmd,$ret);
	my ($olddir,$tmpdir);
	$tofile = $todir."/".$file;
	$fromfile = $fromdir."/".$file;
	if ( ! -f $fromfile )
	{
		DebugString(" $fromfile not file\n");
		if ( -d $fromfile  && ! -e $tofile )
		{
			@cmd = ("mkdir","-p",$tofile);
			DebugString("@cmd\n");
			if ($test != 0)
			{
				$ret = system(@cmd);
				if ( $ret != 0)
				{
					DebugString("Failed\n");
					return -1;
				}
			}	
		}

		return 0;
	}

	{
		$todirname = dirname($tofile);
		if (  -e $todirname  && ! -d $todirname )
		{
			DebugString("$todirname is exist but not dir\n");
			return -1;
		}
		elsif ( ! -e $todirname )
		{
			@cmd = ("mkdir" ,"-p" ,$todirname);
			if ($test != 0)
			{
				$ret = system(@cmd);
				if ($ret != 0)
				{
					DebugString("@cmd Failed\n");
					return -1;
				}
			}
		}

		if ($test != 0)
		{
			if ( ! -d $todirname )
			{
				DebugString("$todirname is not dir\n");
				return -1;
			}
		}

		# now to make the svn add command
		@cmd = ("cp","-f",$fromfile,$tofile);
		DebugString("@cmd\n");
		if ($test != 0)
		{
			$ret = system(@cmd);
			if ( $ret != 0)
			{
				DebugString("@cmd Failed\n");
				return -1;
			}
		}	
	}

	
	if ( $test != 0)
	{
		if ( ! -f $tofile )
		{
			
			DebugString("$tofile not exist\n");
			return -1;
		}
	}

	#
	$olddir = getcwd();
	if ( ! chdir $todir  )
	{
		DebugString("Can not change to $todir\n");
		return -1;
	}

	$tmpdir = getcwd();
	#DebugString("Cur Dir $tmpdir\n");
	
	chdir($olddir);

	return 0;
}


if ($#ARGV < 2)
{
	print STDERR "$0 fromdir todir comparefile $#ARGV\n";
	exit 3;
}

my ($fromdir,$todir,$file) =@ARGV;
my ($fh);

open($fh," < $file") || die "can not open $file for read\n";


while(<$fh>)
{
	my ($line)=$_;
	chomp($line);
	if ( $line =~ m/^\+/o  )
	{
		$line =~ s/^\+ //;
		#DebugString("To add $line\n");
		CopyFile($fromdir,$todir,$line,1);
	}
	elsif ( $line =~ m/^M /o )
{
	$line =~ s/^M //;
	#DebugString("To copy $line\n");
	CopyFile($fromdir,$todir,$line,1);
}
}

close($fh);
