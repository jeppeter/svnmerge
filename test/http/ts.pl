#! perl -w
use strict;
use warngings;
use IO::Socket::INET;
use IO::Select;
use POSIX;
use POSIX ":sys_wait_h";
use Getopt::Std;
use vars qw ($opt_h);



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

	print $fp "$0 [OPTIONS] port\n";
	print $fp "\t-h for this help information\n";
	exit($ec);
}

sub ServerSessionHandle($)
{
	my ($sock)=@_;
	my ($cmd);
	# now first we should get the command
	$cmd = <$sock>;
	if (!defined($cmd) ||
		length($cmd) <= 0)
	{
		exit(0);
	}

	# now we should close the socket
}

sub ChildHandleSock($)
{
	my ($sock)=@_;
	my ($cmd);

	$cmd = <$sock>;
	if (!defined($cmd) ||
		length($cmd))
	{
		DebugString("can not Handle Child read");
		exit(3);
	}

	chomp($cmd);
	DebugString("read cmd ($cmd)\n");

	# now to duplicate the file
	POSIX::dup2(fileno($sock),fileno(STDIN));
	POSIX::dup2(fileno($sock),fileno(STDOUT));
	exec($cmd);
	exit(4);
}

sub AcceptAndFork($)
{
	my ($sock)=@_;
	my ($cpid,$accsock);
	undef($cpid);
	undef($accsock);
	$accsock = $sock->accept();
	if (!defined($accsock))
	{
		return undef;
	}

	$cpid = fork();

	if (!defined($cpid))
	{
		return undef;
	}
	elsif ($cpid == 0)
	{
		# child 
		undef($sock);
		
	}

	# now to close the accept socket
	undef($accsock);
	return $cpid;	
}

sub HandleChildsWaitOver($)
{
	my ($caref) = @_;
	my ($ecnum);
	my ($i);
	my (@cp);
	my ($c,$retc,$err);
	$ecnum = 0;
	@cp = @{$caref};
	for ($i=0;$i<@cp;$i++)
	{
		$c = $cp[$i];
		$retc = waitpid($c,WNOHANG);
		if ($retc == $c )
		{
			# exit ,so let it set undef
			$cp[$i] = undef;
			$ecnum ++;
		}
		elsif ($retc == -1)
		{
			# it may be exited,so we get it the error
			$err = POSIX::Errno();
			if ($err == Errno::ECHILD||
				$err == Errno::EINVAL)
			{
				$cp[$i] = undef;
				$ecnum ++;
			}
		}
	}

	# now test if we have some exit child number
	if ($ecnum)
	{
		@{$caref} = ();
		foreach(@cp)
		{
			$c = $_;
			if (defined($c))
			{
				push(@{$caref},$c);
			}
		}
	}

	return $ecnum;	
}

sub KillChilds($$)
{
	my ($caref,$sig) = @_;
	foreach(@{$caref})
	{
		kill($sig,$_);
	}

	return;
}

sub KillAndWaitChildsExit($)
{
	my ($caref)=@_;
	my ($sig,$times);
	$times = 0;
	while(@{$caref} > 0)
	{
		# now to kill
		if ($times > 10)
		{
			$sig = 9;
		}
		else
		{
			$sig = 2;
		}

		$times ++;
		KillChilds($caref,$sig);
		HandleChildsWaitOver($caref);
		if (@{$caref} > 0)
		{
			sleep(1);
		}
	}

	return ;
	
}

sub ServerAcceptHandle($)
{
	my ($sock)=@_;
	my (@childs,@reads);
	my ($sel);
	my ($cpid);

	$sel = IO::Select->new();
	$sel->add($sock);

	while($st_bRunning)
	{
		undef($cpid);
		@reads = $sel->can_read(10);
		if (@reads > 0)
		{
			$cpid = AcceptAndFork($sock);
			if (defined($cpid))
			{
				push(@childs,$cpid);
			}
		}

		HandleChildsWaitOver(\@childs);
	}

	KillAndWaitChildsExit(\@childs);
	return ;
}

sub BindSocket($)
{
	my ($p)=@_;
	my ($sock);
    $sock = new IO::Socket::INET(LocalHost => '0.0.0.0',
                                 LocalPort => $p,
                                 Proto => 'tcp',
                                 Listen => 5,
                                 Reuse => 1,
                                 Blocking => 0
                                );
    return $sock;
}

my ($sock,$port);
getopt("h");
if (defined($opt_h))
{
	Usage(0);
}

if (@ARGV < 1)
{
	Usage(3);
}

$port = shift @ARGV;
$port = int($port);

$sock = BindSocket($port);
if (!defined($sock))
{
	die "can not bind $port";
}

