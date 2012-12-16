#! perl

use Cwd qw( abs_path getcwd);
use File::Basename;


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


BEGIN
{
	my ($libdir)=GetScriptLibDir();
	push(@INC,$libdir);
}
use TestShared;

my ($ts);

$ts = TestShared->new();
$ts->ThrB();

