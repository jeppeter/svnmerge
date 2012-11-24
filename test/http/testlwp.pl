#! perl -w

use IO::Socket::INET;
use IO::Select;
use IPC::Open2;
use POSIX;
use POSIX ":sys_wait_h";
use threads ('yield',
	'stack_size' => 64*4096,
	'exit' => 'threads_only',
	'stringify');



sub DebugString($)
{
    my ($str)=@_;
    my ($package,$file,$line,$func)=caller(0);

    print STDERR "[$file][$func]:$line $str";
}


my ($st_bRunning)=1;

sub SigHandler
{
	my ($sig)=@_;
    $st_bRunning = 0;
    DebugString("Set $$ $sig\n");
}

sub ClientReadHandle($$)
{
	my ($sock,$timeout)=@_;
	my ($sel);

	$sel = IO::Select->new();
	$sel->add($sock);

		
	
	while($st_bRunning)
	{
		my (@reads,$con);

		@reads = $sel->can_read(1);
		if (@reads <= 0)
		{
			DebugString("Read $$ st_bRunning $st_bRunning\n");
			next;
		}

		$con = <$sock>;
		if (!defined($con))
		{
			DebugString("\n");
			last;
		}
		chomp($con);
        print "Read From Sock $con\n";
	}

	DebugString("\n");
	return;
}

sub ClientHandle($$)
{
    my ($s,$p)=@_;
    my ($sock,$thr);

    $sock = new IO::Socket::INET(
        PeerHost => $s,
        PeerPort => $p,
        Proto => 'tcp'
    ) || die "can not create $s:$p connect";

	$thr = threads->create('ClientReadHandle',$sock,5);
    #parent
    



    while($st_bRunning)
    {
        my ($con);
	    #print "Please Enter to send:";
        $con = <STDIN>;
		DebugString("\n");
        if (defined($con))
        {
            chomp($con);
            print $sock "$con\n";
        }
        else
        {
            last;
        }
    }

	DebugString("\n");

	sleep(3);
	$thr->kill('SIGINT');
	$thr->join();
    undef $sock;
    return 0;
}


sub ServerForkHandle($)
{
    my ($sock)=@_;
    my ($cmd);

    $cmd = "perl redirect.pl";

    # now to dup 
	POSIX::dup2(fileno($sock),fileno(STDIN)) || die "could not dup2 sock for stdin";
	POSIX::dup2(fileno($sock),fileno(STDOUT)) ||die "could not dup2 sock for stdout";

	DebugString("cmd $cmd\n");
	# close socket
	close($sock);
	# parent 
	exec $cmd;
    exit (0);
}

sub ServerHandle($)
{
    my ($p) = @_;
    my ($sock);
    my ($sel);
    undef($sock);

    $sock = new IO::Socket::INET(LocalHost => '0.0.0.0',
                                 LocalPort => $p,
                                 Proto => 'tcp',
                                 Listen => 5,
                                 Reuse => 1,
                                 Blocking => 0
                                );

    $sel=IO::Select->new();
    $sel->add($sock);

    while($st_bRunning)
    {
        my ($accsock,$pip,$pport);
        my ($pid);
        my (@canread);

        @canread = $sel->can_read(1);
        if (@canread <= 0)
        {
            next;
        }


        $accsock = $sock->accept();
        $pip = $accsock->peerhost();
        $pport = $accsock->peerport();
        print "Accept $pip:$pport\n";

        $pid = fork();
        if (!defined($pid))
        {
            $accsock->close();
            $sock->close();
            die "Can not fork";
        }
        elsif ($pid == 0)
        {
            $sock->close();
            ServerForkHandle($accsock);
        }

        $accsock->close();
    }
    return 0;
}

$SIG {'INT'}="SigHandler";

if (@ARGV >= 2)
{
    print "argv @ARGV\n";
    ClientHandle($ARGV[0],$ARGV[1]);
}
else
{
    print "argv @ARGV\n";
    ServerHandle($ARGV[0]);
}
