#! perl

package FindSort;
sub _DebugString
{
    my ($self,$str)=@_;
    my ($package,$file,$line,$func)=caller(0);

    print STDERR "[$file][$func]:$line $str";
}


sub new
{
	my ($class) =@_;
	my ($self) = {};

	bless $self,$class;
	$self->{_cont} = 1;
	return $self;
}




1;
