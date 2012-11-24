#! perl -w

use POSIX ":sys_wait_h";

my ($create)=0;
sub SigChld
{
    my ($child);
    $child = waitpid( -1, WNOHANG ) ;
    if ($child != -1)
    {
        print "SIGNAL CHLD $child\n";
    }
}

sub SigCreate
{
    $create = 1;
}

sub ChildProc
{
    my (@args)=@_;
    my ($cmd);
    print "In Child $$  @args\n";
    sleep(3);
    print "Child $$ exit\n";
    if ("$^O" eq "MSWin32")
    {
        $cmd = "cmd /C \"";
    }
    else
    {
        $cmd = "sh -C '";
    }
    $cmd .= join(" ",@args);
    if ("$^O" eq "MSWin32")
    {
        $cmd .= "\"";
    }
    else
    {
        $cmd .= "'";
    }
    exec $cmd;
    exit (3);
}



sub FatherProc
{
    my ($pid)=-1;
    while(1)
    {
        my ($rpid);
        if ($create && $pid == -1)
        {
            $pid = fork();
            if (!defined($pid) )
            {
                die "can not create fork $!";
            }
            elsif ($pid == 0)
            {
                print "Child @ARGV\n";
                ChildProc(@ARGV);
            }

            print "Child $pid\n";
            $create = 0;
        }
        else
        {
            $create = 0;
        }

        sleep(1);
        $rpid = waitpid( -1, WNOHANG ) ;
        print "rpid $rpid\n";
        if ( $rpid != -1 && $rpid == $pid   )
        {
            $pid = -1;
        }
    }
}

$SIG {'INT'}=\&SigCreate;
$SIG {'CHLD'}=\&SigChld;

print "System $^O\n";
FatherProc();
