#! perl -w


use strict;
use warnings;
use IO::Socket::INET;
use IO::Select;
use POSIX;
use POSIX ":sys_wait_h";
use Getopt::Std;
use vars qw ($opt_h $opt_H $opt_p $opt_v);

########################
#  use this file to test for client to the server
#
########################


my ($st_bRunning)=1;
my ($st_Verbose);
my (@st_Cmds);
my ($st_Host,$st_Port);

sub SigHandleExit
{
	my ($sig)=@_;
	if ("$sig" eq "INT" || 
		"$sig" eq "SIGTERM" )
	{
		$st_bRunning = 0;
	}
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

sub ErrorString($)
{
    my($msg)=@_;
    my($pkg,$fn,$ln,$s)=caller(0);

    {
        printf STDERR "[%-10s][%-20s][%-5d][ERROR]:%s\n",$fn,$s,$ln,$msg;
    }
}


sub Usage
{
	my ($ec)=shift @_;
	my ($error) = shift @_ ;
	my ($fp)=*STDERR;
	if ($ec == 0)
	{
		$fp = *STDOUT;
	}

	if (defined($error))
	{
		print $fp "$error\n";
	}

	print $fp "$0 [OPTIONS] -- commands\n";
	print $fp "\t-h for this help information\n";
	print $fp "\t-H ip address\n";
	print $fp "\t-p port\n";
	print $fp "\t-v verbose mode\n";
	print $fp "\t-- to stop parse\n";	
	print $fp "must specify -s or -d either otherwise it is error\n";
	exit($ec);
}

sub ParseCmds(@)
{
	my (@cmds)=@_;
	my ($i,$curargv);

	for ($i=0;$i<@cmds;$i++)
	{
		$curargv = $cmds[$i];
		if ("$curargv" eq "-h")
		{
			Usage(0);
		}
		elsif ("$curargv" eq "-v")
		{
			$st_Verbose = 1;
		}
		elsif ("$curargv" eq "-H")
		{
			if (($i + 1) >= @cmds)
			{
				Usage(3,"-H need an arg");
			}
			$i ++;
			$st_Host = $cmds[$i];
		}
		elsif ("$curargv" eq "-p")
		{
			if (($i + 1) >= @cmds)
			{
				Usage(3,"-p need an arg");
			}
			$i ++;
			$st_Port = int($cmds[$i]);
		}
		elsif ("$curargv" eq "--")
		{
			$i ++;
			last;
		}
		else
		{
			Usage(3,"Unknown $curargv");
		}
	}

	if ($i >= @cmds)
	{
		
	}
}

