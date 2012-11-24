#! perl -w

use Cwd 'abs_path';
use File::Basename;
use IO::Select;
use IO::Socket::INET;
use POSIX;
use constant ServerCnst =>
{
    Timeout => 5,
    Port => 9722,
};

my($st_bRunning)=1;
my($st_SHApid,$st_Diffpid,$st_Httppid,$st_Verbose,$st_Timeout,$st_Port);



sub GetScriptDir()
{
    my($script_dir);
    $script_dir = dirname(abs_path($0));
    return $script_dir;
}


sub SigExit
{
    $st_bRunning=0;
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

sub ErrorExit($$)
{
    my($ec,$msg)=@_;
    my($p,$f,$l,$s)=caller(0);

    printf STDERR "[%-10s][%-15s][%-5d]:\t%s\n",$f,$s,$l,$msg;
    exit($ec);
}

sub SigChild
{
    my($pid);
    if($^O ne "MSWin32")
    {
        do
        {
            $pid = waitpid(-1, &WNOHANG) ;
            if($pid >= 0 && $pid == $chldpid)
            {
                $chldpid = -1;
            }
        }
        while($pid >= 0);
    }
}

sub RunCmdBack($$$$$)
{
    my($sock,$cmd,$pidref,$resppre,$redirect) = @_;
    my($resp);
    my($cpid,$rpid);

    $cpid = $$pidref;
    $resp = $resppre;

    if($cpid != -1)
    {
        $rpid = waitpid($cpid,WNOHANG);
        if($rpid == $cpid)
        {
            $$pidref = -1;
            $cpid = -1;
        }
    }

    if($cpid != -1)
    {
        $resp .= " 401 $cpid is still running";
        print $sock "$resp\n";
        ErrorString("$resp");
        return -8;
    }

    DebugString("run cmd $cmd");
    $rpid = fork();
    if(!defined($rpid))
    {
        $resp .= " 402 fork $cmd error";
        print $sock "$resp\n";
        ErrorString("$resp");
        return -9;
    }
    elsif($rpid == 0)
    {
        if($redirect)
        {
            POSIX::dup2(fileno($sock),fileno(STDIN))|| die "can not dup2 stdin for $cmd";
            POSIX::dup2(fileno($sock),fileno(STDOUT))|| die "can not dup2 stdout for $cmd";
        }
        undef $sock;
        DebugString("Run $cmd");
        exec("$cmd");
    }

# parent
    $$pidref = $rpid;
    $resp .= " 0 run $cmd succ";
    print $sock "$resp\n";
    DebugString("$resp");
    return 0;
}

sub KillChildAndWait($$)
{
    my($pid,$sig)=@_;
    my($rpid);

    do
    {
        kill(2,$pid);
        $rpid = waitpid($pid,WNOHANG);
        if($rpid != $pid)
        {
            sleep(1);
        }
    }
    while($rpid != $pid && $pid != -1);
    return ;
}

sub KillAllChild()
{
    if((defined($st_Httppid) && $st_Httppid!=-1))
    {
# now to kill it
        KillChildAndWait($st_Httppid,2);
        $st_Httppid = -1;
    }
    if((defined($st_SHApid) && $st_SHApid!=-1))
    {
        KillChildAndWait($st_SHApid,2);
        $st_SHApid = -1;
    }

    if((defined($st_Diffpid) && $st_Diffpid!=-1))
    {
        KillChildAndWait($st_Diffpid,2);
        $st_Diffpid = -1;
    }

    return 0;
}

sub ServerForkHandle($$)
{
    my($sock,$timeout)=@_;
    my($sel,$ret,$con,@reads);
    my($cmd,$resp);
    my($script_dir,@req,$reqcmd);

    $script_dir = GetScriptDir();

    $sel = IO::Select->new();
    $sel->add($sock);

    @reads = $sel->can_read($timeout);
    if(@reads <= 0)
    {
        ErrorString("can not read sock timeout($timeout)$!");
        return -6;
    }

    $con=<$sock>;
    chomp($con);
    DebugString("Receive $con");
    @req = split(" ",$con);
    if(@req <= 1)
    {
        ErrorString("not right request $con");
        return -7;
    }

    $reqcmd = $req[0];
    if("$reqcmd" eq "DS")
    {
# to give the differ files
        @req = split(" ",$con);
# to remove the "DS"
        shift @req;
#        $cmd = "perl $script_dir/dirsha.pl -f - ";
#        $cmd .= join(" ",@req);
		 $cmd = "perl $script_dir/test/http/redirect.pl";
# now to give the

        if(!defined($st_Diffpid))
        {
            $st_Diffpid = -1;
        }
        $ret = RunCmdBack($sock,$cmd,\$st_Diffpid,"DE",1);
    }
    elsif("$reqcmd" eq "HS")
    {
# to calculate the sha for special files
# to remove the "HS"
        shift @req;
        $cmd = "perl $script_dir/dirsha.pl -s - ";
        $cmd .= join(" ",@req);
# now to give the
        if(!defined($st_SHApid))
        {
            $st_SHApid = -1;
        }
        $ret = RunCmdBack($sock,$cmd,\$st_SHApid,"HE",1);
    }
    elsif("$reqcmd" eq "GS")
    {
# start get http server
# to remove the "GS"
        shift @req;
        $cmd = "perl $script_dir/httpdir.pl ";
        $cmd .= join(" ",@req);
        if(!defined($st_Httppid))
        {
            $st_Httppid = -1;
        }
        $ret = RunCmdBack($sock,$cmd,\$st_Httppid,"GE",0);
    }
    elsif("$reqcmd" eq "CS")
    {
# close the get http server
# to remove the "CS"
# now to kill the pid

        KillAllChild();
        $resp = "CE 0 kill all child succ";
        print $sock "$resp\n";
        $ret = 0;
    }
    else
    {
        $resp = "ERROR 401 not recognize $con";
        print $sock "$resp\n";
        ErrorString("$resp");
        $ret = -10;
    }
    return $ret;
}

sub WaitNoHang()
{
    my($rpid);
    if((defined($st_Httppid) && $st_Httppid!=-1))
    {
        $rpid = waitpid($st_Httppid,WNOHANG);
        if($rpid == $st_Httppid)
        {
            $st_Httppid = -1;
        }
    }
    if((defined($st_SHApid) && $st_SHApid!=-1))
    {
        $rpid = waitpid($st_SHApid,WNOHANG);
        if($rpid == $st_SHApid)
        {
            $st_SHApid = -1;
        }
    }

    if((defined($st_Diffpid) && $st_Diffpid!=-1))
    {
        $rpid = waitpid($st_Diffpid,WNOHANG);
        if($rpid == $st_Diffpid)
        {
            $st_Diffpid = -1;
        }
    }

    return ;
}

sub ServerHandle($$)
{
    my($p,$timeout) = @_;
    my($sock);
    my($sel);
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

    DebugString("Listen on $p (timeout:$timeout)");

    while($st_bRunning)
    {
        my($accsock,$pip,$pport);
        my(@reads);
        undef $accsock;
        @reads=$sel->can_read(1);
        if(@reads <= 0)
        {
            WaitNoHang();
            next;
        }

        $accsock = $sock->accept();
        if(!defined($accsock))
        {
            next;
        }
        $pip = $accsock->peerhost();
        $pport = $accsock->peerport();
        DebugString("Accept $pip:$pport");

        ServerForkHandle($accsock,$timeout);
# we should undef this socket for not used it
        undef $accsock;
    }

    KillAllChild();
    DebugString("Exit server");
}

sub Usage
{
    my($ec)  = shift @_ ;
    my($msg) = $ec > 0 ? shift @_ : "";
    my($fp)=STDERR;

    if($ec == 0)
    {
        $fp = STDOUT;
    }
    else
    {
        print $fp "$msg\n";
    }

    print $fp "$0 [OPTIONS] port\n";
    print $fp "\t-h|--help to display this help information\n";
    print $fp "\t-v|--verbose to specify the verbose mode\n";
    print $fp "\t-t|--timeout [sec] to specify the timeout default(".ServerCnst->{Timeout} .")\n";
    print $fp "\t\tport default(".ServerCnst->{Port} .")\n";
    exit($ec);
}

sub ParseParam
{
    my($opt,$arg);
    while(@ARGV)
    {
        $opt = $ARGV[0];
        if("$opt" eq "-h" ||
        "$opt" eq "--help")
        {
            Usage(0);
        }
        elsif("$opt" eq "-v" ||
              "$opt" eq "--verbose")
        {
            shift @ARGV;
            $st_Verbose = 1;
        }
        elsif("$opt" eq "-t" ||
              "$opt" eq "--timeout")
        {
            shift @ARGV;
            if(@ARGV <= 0)
            {
                Usage(3,"Need timeout sec");
            }
            $arg = shift @ARGV;
            $st_Timeout = $arg;
        }
        else
        {
            last;
        }
    }

    if(@ARGV <= 0)
    {
        $st_Port = ServerCnst-> {Port};
    }
    else
    {
        $st_Port = shift @ARGV;
    }

    if(!defined($st_Timeout))
    {
        $st_Timeout = ServerCnst-> {Timeout};
    }

    return ;
}

$SIG {'INT'} = \&SigExit;
$st_bRunning = 1;
ParseParam();
ServerHandle($st_Port,$st_Timeout);


