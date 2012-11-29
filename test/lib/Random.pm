#! perl -w

package Random;

use Time::HiRes qw(  gettimeofday );

sub new
{
	my ($class)=@_;
    my ($self) = {};
	my ($secs,$millsecs);
    bless $self,$class;

   	($secs,$millsecs) = gettimeofday;
   	# now to set for the random seed
   	$millsecs /= 100;
   	srand($millsecs+$secs);

    return $self;
}

sub GetRandom
{
	my ($self,$modnumber) = @_;
	my ($v);

	if ($modnumber)
	{
		$v =int( rand()*$modnumber);
		$v %= $modnumber;
	}
	else
	{
		$v = 0;
	}

	return $v;
}

sub GetRandomFileName
{
	my ($self,$len)=@_;
	my ($i);
	my ($chr,$str);

	$str = "";
	for ($i=0;$i<$len;$i++)
	{
		my ($n);

		$n = $self->GetRandom(62);
		if ($n < 10)
		{
			# 48 is the ascii of '0'
			$chr =chr( 48 + $n);
		}
		elsif ($n >= 10 && $n < 36)
		{
			# 65 is the ascii of 'A'
			$chr = chr(65 + $n - 10);
		}
		elsif ($n < 62)
		{
			# 97 is the asscii of 'a'
			$chr = chr(97 + $n - 36);
		}
		else
		{
			die "can not be here";
		}
		$str .= $chr;
	}
	return $str;
}

1;
