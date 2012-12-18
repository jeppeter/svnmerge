#! perl

use Cwd qw( abs_path getcwd);
use File::Basename;
use File::Touch;
use File::Path qw(make_path remove_tree);


sub GetScriptDir()
{
    my($script_dir);
    $script_dir = dirname(abs_path($0));
    return $script_dir;
}

sub GetScriptLibDir()
{
    my ($libdir);
    my ($libredir);
    $libredir = dirname(abs_path($0));
    $libredir .= "/../lib";
    $libdir= abs_path($libredir);
    return $libdir;
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

sub ErrorExit($$)
{
	my ($exitcode,$msg)=@_;
    my($pkg,$fn,$ln,$s)=caller(0);

    printf STDERR "[%-10s][%-20s][%-5d][INFO]:%s\n",$fn,$s,$ln,$msg;
	exit ($exitcode);
}


BEGIN
{
	my ($script_dir)=GetScriptDir();
	push (@INC,$script_dir);
	$script_dir = GetScriptLibDir();
	push (@INC,$script_dir);
}

use RandDir;

# now we should call the dir

sub RandDirCallBack($$$@)
{
	my ($dir,$fn,$pn,@args)=@_;
	my ($time,$aref)=@args;
	my ($callname);
	my ($ret);

	$callname = "./$pn";
	utime $time,$time,$fn ;
	push(@{$aref},$callname);
	return 0;
}

sub RandirTime($$$$)
{
	my ($edir,$times,$time,$aref)=@_;
	my ($rd,$ret);

	DebugString("edir $edir\n");
	$rd = RandDir->new();
	DebugString("edir $edir\n");
	#if ( -e $edir  )
	{
		remove_tree($edir);
	}
	make_path($edir);

	if ( ! -d $edir)
	{
		ErrorExit(4,"can not make $edir $!");
	}
	
	$rd->SetCallBack(\&RandDirCallBack,$time,$aref);
	$ret = $rd->MakeRandomdirs($edir,$times);

	return $ret;	
}

my ($dir,$times,$time);
my ($aref,@array,@sortarray,$ret,$f);
if (@ARGV < 1)
{
	print STDERR "$0 dir [times] [settime]\n";
	exit(3);
}
DebugString("@ARGV\n");
$dir = shift @ARGV;
DebugString("dir $dir\n");
$times = shift @ARGV || 100;
DebugString("dir $dir\n");
$time = shift @ARGV || time();

@array = ();
$aref = \@array;
$ret = RandirTime($dir,$times,$time,$aref);
if ($ret != 0)
{
	ErrorExit(4,"can not run randirtime correct");
}

@sortarray = sort(@array);

foreach $f (@sortarray)
{
	print "$f\n";
}
