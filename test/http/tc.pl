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

sub DebugString($)
{
    my($msg)=@_;
    my($pkg,$fn,$ln,$s)=caller(0);

    #if(defined($st_Verbose)&&$st_Verbose)
    {
        printf STDERR "[%-10s][%-20s][%-5d][INFO]:%s",$fn,$s,$ln,$msg;
    }
}


sub SigHandleExit
{
	my ($sig)=@_;
	my ($p);
	$p = getpid();
	DebugString("<$p>sig $sig\n");
	if ("$sig" eq "INT" || 
		"$sig" eq "SIGTERM" )
	{
		$st_bRunning = 0;
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
	print $fp "must specify -H and -p either otherwise it is error\n";
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
		Usage(3,"cmds need args");
	}
	@st_Cmds = splice(@cmds,$i);

	if (!defined($st_Port) ||
		!defined($st_Host))
	{
		Usage(3,"Must specify -H and -p");
	}

	return;
}

sub QuoteString($)
{
	my ($s) = @_;
	my ($rets);

	$rets = $s;
	if ($s =~ m/[\s]+/o)
	{
		$rets = "\"$s\"";
	}
	return $rets;
}

sub QuoteStringArray(@)
{
	my (@strs) =@_;
	my (@retstrs);
	foreach(@strs)
	{
		push(@retstrs,QuoteString($_));
	}
	return @retstrs;
}

sub SendRunCmd($@)
{
	my ($sock,@cmds)=@_;
	my ($cmd);

	$cmd = join(' ',QuoteStringArray(@cmds));
	DebugString("cmd ($cmd)\n");
	$sock->send($cmd);
	return 0;
}


#############################
# the socket that read the 
#
#############################
sub ReadSock($$)
{
	my ($outf,$sock)=@_;
	my ($sel);
	my ($buf);

	$sel = IO::Select->new();
	$sel->add($sock);
	while($st_bRunning)
	{
		my (@reads);

		@reads = $sel->can_read(0.1);
		if (@reads > 0)
		{
			$buf = <$sock>;
			if (defined($buf) && length($buf) > 0)
			{
				print $outf "$buf";
			}
		}
		elsif ($st_bRunning)
		{
			sleep(0.9);
		}
	}

	exit(0);
	return ;
}

sub KillChildAndWait($$)
{
	my ($pid,$sig)=@_;
	my ($rpid,$times);
	$times = 0;
	do
	{
		if ($times < 10)
		{
			kill($sig,$pid);
		}
		else
		{
			# we kill it rightly
			kill(9,$pid);
		}		
		$rpid = waitpid($pid,WNOHANG);
		if ($rpid != $pid)
		{
			sleep(1);
			$times ++;
			
		}
	}while($pid!= $rpid);
	return ;
}


sub ConnectAndHandle($$$@)
{
	my ($inf,$outf,$sock,@cmds)=@_;
	my ($ret,$l,$cpid);
	undef($cpid);

	DebugString("send @cmds\n");
	# now first to send cmd
	$ret = SendRunCmd($sock,@cmds);
	if ($ret < 0)
	{
		return $ret;
	}

	# now to fork and give the 
	$cpid = fork();
	if (!defined($cpid))
	{
		return -3;
	}
	elsif ($cpid == 0)
	{
		# child 
		ReadSock($outf,$sock);
		exit(3);
	}

	# this is parent
	while(<$inf>)
	{
		my ($l) = $_;
		$sock->send($l);
	}

	KillChildAndWait($cpid,2);
	return 0;
}

sub ConnectRemote($$)
{
	my ($ip,$port)=@_;
	my ($sock);
	undef($sock);
    $sock = new IO::Socket::INET(PeerHost => $ip,
                                 PeerPort => $port,
                                 Proto => 'tcp',
                                 Blocking => 0
                                );

	DebugString("Connect $ip:$port <$sock>\n");
	return $sock;	
}
my ($st_Sock);
ParseCmds(@ARGV);



# now to connect for host
$SIG{'INT'}=\&SigHandleExit;
$SIG{'TERM'}=\&SigHandleExit;

$st_Sock = ConnectRemote($st_Host,$st_Port);
if (!defined($st_Sock))
{
	die "can not connect to $st_Host:$st_Port";
}

$st_Sock->autoflush(1);
ConnectAndHandle(*STDIN,*STDOUT,$st_Sock,@st_Cmds);
undef($st_Sock);

