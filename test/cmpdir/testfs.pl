#! perl

use File::Basename;
use Cwd qw( abs_path getcwd);

sub GetScriptDir()
{
    my($script_dir);
    $script_dir = dirname(abs_path($0));
    return $script_dir;
}

sub DebugString($)
{
    my($msg)=@_;
    my($pkg,$fn,$ln,$s)=caller(0);

    {
        printf STDERR "[%-10s][%-20s][%-5d][INFO]:%s\n",$fn,$s,$ln,$msg;
    }
}

BEGIN
{
	my ($script_dir)=GetScriptDir();
	my ($upperdir);

	$upperdir = abs_path("$script_dir/../..");

	push (@INC,$upperdir);
	push (@INC,$script_dir);	
}

use FindSort;


# now to take the print
sub PrintFile($$$$@)
{
	my ($dir,$fname,$curd,$pname,@args)=@_;
	$fname =~ s/^\Q$dir\E[\/\\]+//;
	print STDOUT "$fname\n";
	return 0;
}

my ($d);

foreach $d (@ARGV)
{
	my ($fs);
	my (@dummyarra);
	my ($ret);
	my ($addr);
	push(@dummyarray,"hello");
	push(@dummyarray,"work");
	$fs = FindSort->new();
	$addr = \&PrintFile;
	$fs->SetFilters("\\.git");
	$fs->SetCallBack($addr,@dummyarray);
	print "Start Scan $d\n";
	$ret = $fs->ScanDirs($d);
	if ($ret != 0)
	{
		print STDERR "Error($d) ".$fs->GetErrorMsg()."\n";
		exit (3);
	}
	undef($fs);
}

