#! perl

# running test array package
package TA;

sub DebugString($)
{
    my ($str)=@_;
    my ($package,$file,$line,$func)=caller(0);

    print STDERR "[$file][$func]:$line $str";
}


sub new
{
    my ($class) = @_;
    my ($self) = {};

    bless $self,$class;

    return $self;
}

sub SetArray
{
    my ($self,$ar,$hr)= @_;
    my (%hv,@av,@tmp);
    my (@last);
    my ($lastc);
    @av = @$ar;
    @tmp = sort @av;
    undef($lastc);
    foreach(@tmp)
    {
    	my ($c)=$_;

    	if (defined($lastc))
    	{
    		if ("$lastc" eq "$c")
    		{
    			next;
    		}
    	}
    	push (@last,$c);
    	$lastc = $c;
    }
    %hv = %$hr;
    $self->{_arrs} = [ @last ];
    $self->{_hashes} = {%hv};
    $self->{_curidx} = 0;
    #DebugString("tmp @tmp\n");
    return $self;
}

sub __GetCurIdx
{
    my ($self)=@_;

    if (defined($self->{_arrs}) && defined($self->{_arrs} [$self->{_curidx}]))
    {
        return $self->{_arrs}[$self->{_curidx}];
    }

    return undef;
}

sub __GetNextIdx
{
    my ($self) = @_;

    if (defined($self->{_arrs}) && defined($self->{_arrs} [$self->{_curidx}+1]))
    {
        $self-> {_curidx} += 1;
        return $self-> {_arrs}[$self->{_curidx}];
    }

    if (defined($self->{_arrs}) && defined($self->{_arrs} [$self->{_curidx}]))
    {
        $self->{_curidx} += 1;
    }
    return undef;
}

sub CompareArray
{
    my ($self,$other,$dir)=@_;
    my ($sv,$ov,$ista,$tov);
    my ($str,$cont);

    $ista = $other->isa("TA");
    if (!$ista)
    {
        die "param is not TA class";
    }


# to give the value
	
    $str = "AS $dir\n";
# now to compare the job
    while(1)
    {
        $sv = $self->__GetCurIdx();
        if (defined($sv))
        {
# now to give the
			#DebugString("sv $sv\n");
            $ov = $other->__GetCurIdx();
            if (defined($ov))
            {

            	#DebugString("ov $ov\n");
                do
                {
                    $cont = 0;
                    $ov = $other->__GetCurIdx();
                    if (defined($ov))
                    {

                        if (("$ov" lt "$sv"))
                        {
                            $str .= "- $ov\n";
                            $tov = $other->__GetNextIdx();
                            if (defined($tov))
                            {
                                $cont =1;
                            }
                            else
                            {
                            	# nothing to do ,so add it                            	
                            	$str .= "+ $sv\n";
                            }
                        }
                        elsif ("$ov" eq "$sv")
                        {
# now to see if it is modified
							my ($shv,$ohv);
							
                            if ( (defined($self->{_hashes}->{$sv}) && defined($other->{_hashes}->{$ov})))
                            {
                            	$shv = $self->{_hashes}->{$sv};
                            	$ohv = $other->{_hashes}->{$ov};
                            	if ("$shv" ne "$ohv")
                            	{
                                	$str .= "M $ov\n";
                                }
                            }
                            elsif (defined($self->{_hashes}->{$ov}) || defined($other->{_hashes}->{$sv}))
                            {
                            	$str .= "M $ov\n";
                            }
                            #get next to compare
                            $other->__GetNextIdx();
                        }
                        else
                        {
                            $str .= "+ $sv\n";
                        }
  	                    #DebugString("sv $sv <=> ov $ov str\n");
  	                    #DebugString("$str");
                    }
                    else
                    {
                        $str .= "+ $sv\n";
                    }
                }
                while($cont);

            }
            else
            {
            	$str .= "+ $sv\n";
            }
        }
        else
        {
# now we should set the str of not set
            do
            {
                $cont = 0;
                $ov = $other->__GetCurIdx();
                if (defined($ov))
                {
                    $str .= "- $ov\n";
                    if (defined($other->__GetNextIdx()))
                    {
                        $cont = 1;
                    }
                }
            }
            while ($cont);
# break out
            last;
        }
        $self->__GetNextIdx();
    }


# now to set the last one
    $str .= "AE $dir\n";
    return $str;

}


1;


