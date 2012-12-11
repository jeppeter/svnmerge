#! perl

package RandDir;

use Random;
use File::Touch;
use Cwd qw( abs_path getcwd);
use File::Basename;

sub new
{
	my ($class)=@_;
    my ($self) = {};
    bless $self,$class;
    $self->{_RandomClass}= Random->new();
    return $self;
}

sub SetCallBack($$@)
{
	my ($self,$callfunc,@callargs)=@_;

	$self->{_callfunc} = $callfunc;
	$self->{_callargs} = [@callargs];
	return $self;
}

sub __SetError($$$)
{
	my ($self,$exitcode,$msg)=@_;
	$self->{_msg}=$msg;
	return $exitcode;
}

sub GetError($)
{
	my ($self)=@_;

	return defined($self->{_msg}) ? $self->{_msg} : "";
}

sub MakeRandomdirs($$$)
{
	my ($self,$dir,$times)=@_;
	my ($r,$isdir,$fn,$i,$p,$curs,$d,$f);
	my ($absdir);
	my ($rand,$hasmkdir,$hastouchfile);
	my ($ret);
	my (@callargs);

	@callargs = ();
	if (defined($self->{_callargs}))
	{
		@callargs = @{$self->{_callargs}};
	}

	# now to read the absolute dir
	$absdir = abs_path($dir);
	$rand = $self->{_RandomClass};

	if ($times < 0)
	{
		return $self->__SetError(-4,"$time is not valid");
	}

	for ($i=0;$i< $times ; $i++)
	{
		$hasmkdir = 0;
		$hastouchfile = 0;
		$p = "";
		do
		{
			$isdir = $rand->GetRandom(2);
			$curs = $rand->GetRandomFileName(12);
			$p .= "$curs";
			if ($isdir)
			{
				$p .= "/";
			}
		}while($isdir);

		$fn = "$absdir/$p";

		if (len($f) > 200)
		{
			# we can not make file in more 200 characters
			next;
		}

		# now we should make directory
		$d = dirname($f);
		$f = basename($f);

		if (  -e $d && ! -d $d)
		{
			# now make this directory
			next ;
		}

		if ( ! -e $d )
		{
			make_path($d);
			$hasmkdir = 1;
		}

		if ( -e $fn  && ! -f $fn )
		{
			# we should remove the directory we make
			if ( $hasmkdir )
			{
				remove_tree($d);
			}
			next;
		}

		if ( ! -e $fn )
		{
			touch($fn);
			$hastouchfile = 1;
		}

		# now to call back function
		if (defined($self->{_callfunc}))
		{
			$ret = $self->{_callfunc}($dir,$fn,$p,@callargs);
			if ($ret != 0)
			{
				return $self->__SetError($ret , "can not run call back on $fn($dir/$p)");
			}
		}		
		
	}

	return 0;
}



1;
