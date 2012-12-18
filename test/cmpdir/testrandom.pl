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


use Random;

my ($r) = Random->new();
my ($num) =@ARGV ?  shift @ARGV:0;
my ($i,$name,$rn);

for ( $i=0;$i<$num || $num == 0;$i++)
{
	$rn = $r->GetRandom(1000);

	if ($rn % 2)
	{
		$rn = $r->GetRandom(10000);
		print "[$i] random number $rn\n";
	}
	else
	{
		$rn %= 200;
		$name=$r->GetRandomFileName($rn);
		print "[$i] name:size[$rn] $name\n";		
	}
}
