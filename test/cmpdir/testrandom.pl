#! perl -w

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
