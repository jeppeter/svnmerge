#! perl -w

use POSIX();

my ($st_Stdin,$st_Stdout,$st_Stderr);

sub DebugString($)
{
    my ($str)=@_;
    my ($package,$file,$line,$func)=caller(0);

    print STDERR "[$file][$func]:$line $str";
}


sub Usage($)
{
	my ($ec)=@_;
	my ($fp)=STDERR;
	if ($ec == 0)
	{
		$fp = STDOUT;
	}

	print $fp "$0 [OPTIONS] command\n";
	print $fp "-h for this help information\n";
	print $fp "-i input  for stdin\n";
	print $fp "-o output for stdout\n";
	print $fp "-e errput for stderr\n";
	print $fp "-- after this ,will give the command\n";

	exit($ec);
}

sub ParseParam
{
	my ($opt,$arg);

	while(@ARGV)
	{
		$opt = shift @ARGV;
		if ("$opt" eq "-h")
		{
			Usage(0);
		}
		elsif ("$opt" eq "-i")
		{
			if (@ARGV == 0)
			{
				Usage(3);
			}
			$st_Stdin = shift @ARGV;
		}
		elsif ("$opt" eq "-o")
		{
			if (@ARGV == 0)
			{
				Usage(3);
			}
			$st_Stdout = shift @ARGV;
		}
		elsif ("$opt" eq "-e")
		{
			if (@ARGV == 0)
			{
				Usage(3);
			}
			$st_Stderr = shift @ARGV;
		}
		elsif ("$opt" eq "--")
		{
			last;
		}
		else
		{
			Usage(3);
		}
	}

	if (@ARGV == 0)
	{
		Usage(3);
	}

	return ;
}


sub RunCmd(@)
{
	my (@cmds)=@_;
	my ($cmdstr);
	my ($pid);

	$cmdstr = join(" ",@cmds);

	DebugString("cmd $cmdstr\n");
	$pid = fork();
	if (!defined($pid))
	{
		die "could not fork";
	}
	elsif ($pid == 0)
	{
		sleep(1);
		DebugString("stdin ".fileno(STDIN)."\n");
		DebugString("stdout ".fileno(STDOUT)."\n");
		DebugString("stderr ".fileno(STDERR)."\n");

		if (defined($st_Stdin))
		{
			my ($fh);
			open($fh,"<$st_Stdin")|| die "could not open $st_Stdin for stdin";
			POSIX::dup2(fileno($fh),fileno(STDIN)) || die "could not dup2 stdin";
			close($fh);
		}

		if (defined($st_Stdout))
		{
			my ($fh);
			open($fh,">$st_Stdout") || die "could not open $st_Stdout for stdout";
			POSIX::dup2(fileno($fh),fileno(STDOUT)) || die "could not dup2 stdout";
			close($fh);
		}

		if (defined($st_Stderr))
		{
			my ($fh);
			open($fh,">$st_Stderr")|| die "could not open $st_Stderr for stderr";
			POSIX::dup2(fileno($fh),fileno(STDERR)) || die "could not dup2 stderr";
			close($fh);
		}

		exec $cmdstr;
		exit (3);
	}

	# this is father ,so exit
	exit (0);
}

ParseParam();
RunCmd(@ARGV);
