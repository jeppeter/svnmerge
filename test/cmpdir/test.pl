#! perl -w


use File::Path qw(make_path remove_tree);
use File::Remove 'remove';
use File::Touch;
use Cwd qw( abs_path getcwd);
use File::Basename;


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

    if(defined($st_Verbose)&&$st_Verbose)
    {
        printf STDERR "[%-10s][%-20s][%-5d][INFO]:%s\n",$fn,$s,$ln,$msg;
    }
}


BEGIN
{
	my ($script_dir)=GetScriptDir();

	push (@INC,$script_dir);
	
}

use Random;
use TA;


sub TestIsFile($)
{
    my ($f)=@_;
    if ( -f $f )
    {
        return 1;
    }

    return 0;
}

sub TestIsDir()
{
    my ($f)=@_;
    if ( -d $f )
    {
        return 1;
    }

    return 0;
}

sub MustBeFile($)
{
    my ($f) = @_;

    if (! TestIsFile($f))
    {
        die "$f is not regular file\n";
    }
}

sub ExDir($)
{
	my ($f)=@_;
	my (@ret);
	my (@s);
	my ($i);
	my ($l);
	@s = split("/",$f);
	$l="";
	for($i=0;defined($s[$i]);$i++)
	{
		my ($c)=$s[$i];

		if ($i==0)
		{
			$l .= "$c";
		}
		else
		{
			$l.="/$c";
		}

		push(@ret,$l);		
	}

	return @ret;
}

sub ShouldBeDir($)
{
	my ($file) = @_;

	if ( $file =~ m#\/$#o )
	{
		return 1;
	}
	return 0;
}

sub TouchFileDir($$)
{
	my ($dir,$file) = @_;
	my ($fname,$now);
	my ($dirn);
	# first to test it should be dir or file
	$fname = "$dir/"."$file";
	$dirn = dirname($fname);
	if ( ! -d $dirn )
	{
		if ( -e $dirn )
		{
			remove($dirn);
		}
		make_path($dirn);
	}

	if ( ! -d $dirn )
	{
		die "could not make $dir\n";
	}

	# now to touch the file
	if ( ! -e $fname )
	{
		touch($fname);
	}

	return 0;
}

sub ChangeFileContent($$)
{
	my ($file,$content)=@_;
	my ($fh);

	open($fh,">$file") || die "could not open $file for write";

	print $fh "$content";
	close($fh);

	return 0;	
}

sub SetRandomFile($$$$)
{
	my ($dir,$ar,$hr,$num)=@_;
	my ($i);
	my ($rv,$rc,$fname,$tname);


	$rc = Random->new();

	# now to give the random
	for ($i=0;$i<$num;$i++)
	{
		$tname="";
		do
		{
			$rv = $rc->GetRandom(99);
			$fname = $rc->GetRandomFileName(10);
			if (($rv %3) ==0)
			{
				$tname .= "$fname";
			}
			else
			{
				$tname .= "$fname/";
			}
		} while(($rv % 3));

		if (length("$dir/$tname")>= 200)
		{
			# long name can not accept
			next;
		}
		$fname = $rc->GetRandomFileName(60);
		push (@{$ar},$tname);
		$hr->{$tname}=$fname;
	}

	return 0;
}

sub MakeFile($$$)
{
	my ($dir,$ar,$hr)=@_;
	my ($curf,$i,$curc,$tname);
	# now to give the
	for ($i=0;defined($ar->[$i]);$i++)
	{
		$curf = $ar->[$i];
		$curc = $hr->{$curf};
		$tname = "$dir/$curf";
		TouchFileDir($dir,$curf);
		ChangeFileContent($tname,$curc);	
	}
}

sub ExpandDir($)
{
	my ($ar)=@_;
	my ($i);
	my (@ret,@tmpa);

	for ($i=0;defined($ar->[$i]);$i++)
	{
		@ret = ExDir($ar->[$i]);
		foreach(@ret)
		{
			push(@tmpa,$_);
		}
	}

	foreach(@tmpa)
	{
		push(@{$ar},$_);
	}

	return 0;
}

sub RandomFile($$)
{
	my ($srcdir,$dstdir)=@_;
	my (@aa,@ba,%ah,%bh,@tmpa,%tmph);
	my ($ata,$bta,$cmpstr);
	my ($cmd,$plstr,$cmdh);
	my ($curdir);
	my ($script_dir);
	$script_dir = GetScriptDir();
	# now to make hash
	undef(@aa);
	undef(%ah);
	undef(@ba);
	undef(%bh);
	SetRandomFile($srcdir,\@aa,\%ah,100);
	@ba=@aa;
	%bh=%ah;

	# now to append 
	undef(@tmpa);
	undef(%tmph);
	SetRandomFile($dstdir,\@tmpa,\%tmph,20);
	foreach(@tmpa)
	{
		my ($v)=$_;
		push(@ba,$v);
		$bh{$v} = $tmph{$v};
	}

	# now to append a
	undef(@tmpa);
	undef(%tmph);
	SetRandomFile($srcdir,\@tmpa,\%tmph,20);
	foreach(@tmpa)
	{
		my ($v)=$_;
		push(@aa,$v);
		$ah{$v} = $tmph{$v};
	}
	
	

	MakeFile($srcdir,\@aa,\%ah);
	MakeFile($dstdir,\@ba,\%bh);

	# now to make sure that it will extend the directory
	ExpandDir(\@aa);
	ExpandDir(\@ba);

	# now to do the perl  dircmp
	$ata=TA->new();
	$bta=TA->new();

	$ata->SetArray(\@aa,\%ah,$srcdir);
	$bta->SetArray(\@ba,\%bh,$dstdir);


	$cmpstr = $ata->CompareArray($bta,$srcdir);

	$curdir=getcwd();
	DebugString("change to $script_dir/../..");
	chdir("$script_dir/../..");
	$cmd = "perl dircmp.pl -s $srcdir -d $dstdir ";
	if ("$^O" eq "MSWin32")
	{
		$cmd .= " 2>NUL";
	}
	else
	{
		$cmd .= " 2>/dev/null";
	}
	$cmd .= " | ";

	open ($cmdh,$cmd) || die "could not run $cmd";

	$plstr = "";
	while(<$cmdh>)
	{
		my ($l)=$_;		

		$plstr .= $l;
	}

	close($cmdh);
	chdir($curdir);

	if ("$cmpstr" ne "$plstr")
	{
		print STDERR "run $cmd are not eq TA result\n";
		print STDERR "=====================================\n";
		print STDERR "cmdstr :\n";
		print STDERR "$cmpstr";
		print STDERR "\n";
		print STDERR "=====================================\n";
		print STDERR "plstr :\n";
		print STDERR "=====================================\n";
		print STDERR "$plstr";
		print STDERR "\n";
		print STDERR "=====================================\n";
		return -1;
	}
	return 0;
}


sub NumberRandom($$$)
{
	my ($src,$dst,$num)=@_;
	my ($i,$ret);
	my ($absrc,$abdst);

	$absrc=abs_path($src);
	$abdst=abs_path($dst);
	if ( ("$absrc" ne "$src" )|| ("$abdst" ne "$dst"))
	{
		print STDERR "Can not run in relative path\n";
		return -1;
	}

	for ($i=0;$i<$num || $num == 0;$i++)
	{
		if ($i && (($i)%10)==0)
		{
			print STDERR "\n";
		}
		if ((($i) % 10) == 0)
		{
			print STDERR "$i:\t";
		}
		print STDERR ".";
		remove_tree($src);
		remove_tree($dst);
		
		make_path($src);
		make_path($dst);
		$ret=RandomFile($src,$dst);
		if ($ret != 0)
		{
			return $ret;
		}
	}

	return 0;
}


my ($testdir,$num)=@ARGV;
my ($ret);
my ($srcdir,$dstdir);
if (!defined($testdir))
{
	print STDERR "$0 dir [num]\n";
	exit (3);
}

$testdir=abs_path($testdir);

$srcdir="$testdir/a";
$dstdir="$testdir/b";

remove_tree($srcdir);
remove_tree($dstdir);
make_path($srcdir);
make_path($dstdir);

if (!defined($num))
{
	$num = 10;
}

$ret=NumberRandom($srcdir,$dstdir,$num);
exit ($ret);

