#! perl -w

use IO::Socket::INET;
use IO::Select;
use POSIX;
use POSIX ":sys_wait_h";

my ($st_bRunning)=1;
my ($st_Verbose,$st_FHIn);

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

sub KillChildAndWait($$)
{
	my ($pid,$sig)=@_;
	my ($rpid);
	do
	{
		kill($sig,$pid);
		$rpid = waitpid($pid,WNOHANG);
		if ($rpid != $pid)
		{
			sleep(1);
		}
	}while($pid!= $rpid);
	return ;
}


sub ClientStdinHandle($$)
{
    my ($sock,$timeout)=@_;
    while($st_bRunning)
    {
        my ($con)=<$st_FHIn>;
        if (!defined($con))
        {
        	DebugString("read fileno ".fileno($st_FHIn)." error  $!");
            last;
        }
        chomp($con);
        DebugString("Send $con  fd ".fileno($st_FHIn)."");
        print $sock "$con\n";
        DebugString("Send $con complete");
    }
    DebugString("");
    undef $sock;
    exit(0);
}

# 1 for read one
# 0 for not read one
# -1 for error 
# 2 for last one
sub HandleReadOne($$$)
{
	my ($sel,$sock,$str)=@_;
	my ($ret)=0;
	my (@reads);
	my ($con);

	@reads = $sel->can_read(1);
	if (@reads <= 0)
	{
		return 0;
	}

	$con = <$sock>;
	if (!defined($con))
	{
		# last one
		return 2;
	}

	chomp($con);
	print STDOUT "$con\n";
	return 1;
}

sub ClientDiffHandle($$$)
{
    my ($sock,$remotedir,$timeout) = @_;
    my ($sel,@reads,$cpid,$rpid,@res);
    my ($hasnotread);

    $sel = IO::Select->new();
    $sel->add($sock);
    print $sock "DS $remotedir\n";
    @reads=$sel->can_read($timeout);
    if (@reads<=0)
    {
        ErrorString("read sock timeout $timeout");
        return -3;
    }

# now to read it
    $con=<$sock>;
    if (!defined($con))
    {
    	ErrorString("can not read sock $!");
    	return -3;
    }
    chomp($con);

    DebugString("Read sock $con");
    @res=split(" ",$con);
    if (@res <= 1)
    {
        ErrorString("Read $con not right");
        return -4;
    }

    if ($res[0] ne "DE" ||
            $res[1] ne "0")
    {
        ErrorString("Read $con not right");
        return -5;
    }

# now to fork the write sock
    $cpid = fork();
    if (!defined($cpid))
    {
        die "could not fork $!";
    }
    elsif ($cpid == 0)
    {
# child to handle
		ClientStdinHandle($sock,$timeout);
        ErrorString("Client Second Should not return here");
        exit (3);
    }

# parent
	$hasnotread = 0;
    while ($st_bRunning)
    {
    	my ($ret,$con);
    	$ret = HandleReadOne($sel,$sock,"Diff");
    	if ($ret == 2)
    	{
    		last;
    	}
    	elsif ($ret == 0)
    	{
    		$hasnotread ++;
    		if ($hasnotread >= $timeout)
    		{
    			ErrorString("Read Diff Timeout($timeout)");
    			last;
    		}
    		next;
    	}
    	elsif ($ret < 0)
    	{
    		ErrorString("Read Diff error $!");
    		last;
    	}
    	elsif ($ret == 1)
    	{
    		$hasnotread = 0;
    	}
    }

	KillChildAndWait($cpid,2);
    $cpid = -1;
    return 0;
}


sub ClientSHAHandle($$$)
{
    my ($sock,$remotedir,$timeout)=@_;
# now to give the sha
    my ($sel,@reads,$con,@res);
    my ($cpid,$rpid);
	my ($hasnotread);

    $sel = IO::Select->new();
    $sel->add($sock);
    print $sock "HS $remotedir\n";
    @reads = $sel->can_read($timeout);
    if (@reads <= 0)
    {
        ErrorString("read HS $remotedir timeout($timeout)");
        return -1;
    }

    $con=<$sock>;
    if (!defined($con))
    {
        ErrorString("not read sock $!");
        return -2;
    }
    chomp($con);
    DebugString("Read Sock $con");
    @res = split(" ",$con);
    if (@res < 2)
    {
        ErrorString("not right $con content");
        return -3;
    }

    if ($res[0] ne "HE" ||
            $res[1] ne "0")
    {
    	ErrorString("HS error $con");
    	return -4;
    }

	$cpid = fork();
	if (!defined($cpid))
	{
		die "could not fork on sha";
	}
	elsif ($cpid == 0)
	{
		ClientStdinHandle($sock,$timeout);
		ErrorString("should not return here");
		exit (3);
	}

	# parent
	$hasnotread = 0;
	while($st_bRunning)
	{
    	my ($ret);
    	$ret = HandleReadOne($sel,$sock,"SHA");
    	if ($ret == 2)
    	{
    		last;
    	}
    	elsif ($ret == 0)
    	{
    		$hasnotread ++;
    		if ($hasnotread >= $timeout)
    		{
    			DebugString("Read SHA Timeout($timeout)\n");
    			last;
    		}
    		next;
    	}
    	elsif ($ret < 0)
    	{
    		DebugString("Read SHA error $!\n");
    		last;
    	}
    	elsif ($ret == 1)
    	{
    		$hasnotread = 0;
    	}
	}

	KillChildAndWait($cpid,2);
	return ;
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

	DebugString("Connect $ip:$port $sock");
	return $sock;	
}

sub Usage
{
	my ($ec)=shift @_;
	my ($error) = $ec ? shift @_ : "";
	my ($fp)=STDERR;
	if ($ec == 0)
	{
		$fp = STDOUT;
	}
	else
	{
		print $fp "On Error $error\n";
	}


	print $fp "$0 [OPTIONS] ip port remotedir\n";
	print $fp "-h for this help information\n";
	print $fp "-s for sha\n";
	print $fp "-d for diff\n";
	print $fp "-t timeout to specify if not it is 10\n";
	print $fp "-v verbose mode\n";
	print $fp "must specify -s or -d either otherwise it is error\n";

	exit($ec);
}


use Getopt::Std  ;
use vars qw($opt_s $opt_d $opt_h $opt_t $opt_v);
my ($ip,$port,$remotedir,$timeout);
my ($sock);
getopts("s:d:ht:v");

if (defined($opt_h))
{
	Usage(0);
}


if (@ARGV < 3)
{
	Usage(3,"Must Specify IP Port Remotedir");
}

$ip = shift @ARGV;
$port = shift @ARGV;
$remotedir = shift @ARGV;
$timeout=10;

$SIG{'INT'}=\&SigHandleExit;
$SIG{'TERM'}=\&SigHandleExit;
if (defined($opt_t))
{
	$timeout = $opt_t;
}

if (defined($opt_v))
{
	$st_Verbose = 1;
}

$sock = ConnectRemote($ip,$port) ;
if (!defined($sock))
{
	die "could not connect $ip:$port $!";
}

if (defined($opt_s))
{
	if ("$opt_s" eq "-")
	{
		$st_FHIn = STDIN;
	}
	else
	{
		open($st_FHIn,"<$opt_s") || die "can not open $opt_s for sha";
	}
	ClientSHAHandle($sock,$remotedir,$timeout);
	if (fileno($st_FHIn) != fileno(STDIN))
	{
		close($st_FHIn);
	}
	undef $st_FHIn;
}
elsif (defined($opt_d))
{
	if ("$opt_d" eq "-")
	{
		$st_FHIn = STDIN;
	}
	else
	{	
		undef ($st_FHIn);
		DebugString("Open $opt_d");
		open($st_FHIn,"<$opt_d") || die "can not open $opt_d for diff";
	}
	ClientDiffHandle($sock,$remotedir,$timeout);
	if (fileno($st_FHIn) != fileno(STDIN))
	{
		close($st_FHIn);
	}
	undef $st_FHIn;
}
else
{
	Usage(3,"Must Specify the -d or -s");
}

undef $sock;
