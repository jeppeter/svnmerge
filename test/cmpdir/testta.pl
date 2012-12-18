#! perl -w

use Cwd qw( abs_path getcwd);
use File::Basename;


sub GetScriptLibDir()
{
    my ($libdir);
    my ($libredir);
    $libredir = dirname(abs_path($0));
    $libredir .= "/../lib";
    $libdir= abs_path($libredir);
    return $libdir;
}


sub GetScriptDir()
{
    my($script_dir);
    $script_dir = dirname(abs_path($0));
    return $script_dir;
}


BEGIN
{
	my ($script_dir)=GetScriptDir();
	push (@INC,$script_dir);
	$script_dir = GetScriptLibDir();
	push (@INC,$script_dir);
	
}


use TA;


sub DebugString($)
{
    my ($str)=@_;
    my ($package,$file,$line,$func)=caller(0);

    print STDERR "[$file][$func]:$line $str";
}


sub GetFile($$$)
{
    my($file,$ar,$hr)=@_;

    my($fh);

    open($fh,"<$file") ||die "could not open $file for read" ;

    while(<$fh>)
    {
        my(@a,$line);
		$line = $_;
		chomp($line);
        @a = split(/ /,$line);
        if($#a >= 0)
        {
            push(@{$ar},$a[0]);
            if($#a > 0)
            {
                $hr-> {$a[0]}=$a[1];
                DebugString("hr{$a[0]} =>$a[1]\n");
            }
        }
    }

    close($fh);

    return 0;
}

if($#ARGV<2)
{
    print STDERR "$0 Afile Bfile dir\n";
    print STDERR "File LineFormat [name] [diff]\n";
    exit 3;
}

my($afile,$bfile,$dir)=@ARGV;
my(@aa,%ah,@ba,%bh);
my($ata,$bta);
my($str);
GetFile($afile,\@aa,\%ah);
GetFile($bfile,\@ba,\%bh);

DebugString("a @aa\n");
DebugString("b @ba\n");


$ata=TA->new();
$bta=TA->new();

$ata->SetArray(\@aa,\%ah);
$bta->SetArray(\@ba,\%bh);

$str = $ata->CompareArray($bta,$dir);

print "$str";

