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

sub ServerAcceptHandle($)
{
	my ($sock)=@_;
	my (@childs,@reads);
	my ($sel);

	$sel = IO::Select->new();
	$sel->add($sock);

	while($st_bRunning)
	{
		@reads = $sel->can_read(10);
		if (@reads > 0)
		{
			
		}
	}

	
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

