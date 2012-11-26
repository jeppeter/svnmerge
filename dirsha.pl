#! perl -w

use File::Find;
use Digest::SHA1;
use Getopt::Std;
use ShaDir;
use IO::Handle;
use vars qw ($opt_h $opt_f $opt_s $opt_v $opt_V);
my (@filters);
my (@rawfiles);

sub DebugString($)
{
    my ($msg)=@_;
    my($pkg,$fn,$ln,$s)=caller(0);

    printf STDERR "[%-10s][%-20s][%-5d][INFO]:%s\n",$fn,$s,$ln,$msg;
}
sub DirFilter
{
    my ($curfile)=$_;
    my ($ret);
    $ret = 0;
    foreach (@filters)
    {
        my($curfilter)=$_;
        if ($File::Find::name =~ m/$curfilter/)
        {
            $ret = 1;
            last;
        }
    }
    if ($ret == 0)
    {
        if ( (-f $File::Find::name) || ( -d $File::Find::name ))
        {
            push(@rawfiles,$File::Find::name);
        }
    }
}

sub TranslateFile($@)
{
    my ($dir,@tmpfiles)=@_;
    my (@infiles);
    foreach(@tmpfiles)
    {
        my ($curfile)=$_;
        $curfile =~ s#\Q$dir\E##;
# to remove the dir file
        do
        {
            $curfile =~ s#^\/##;
        }
        while($curfile =~ m#^\/#o);

        push(@infiles,$curfile);
    }

    return @infiles;
}

sub GetSha($$)
{
    my ($dir,$file)=@_;
    my ($filename);
    my ($sha,$fd,$digest);

    $filename = "$dir"."/$file";
    open ($fd,"< $filename") || die "can not open $filename";
    $sha = Digest::SHA1->new;
    $sha->addfile($fd);
    $digest = $sha->b64digest;

    close($fd);
    return $digest;
}

sub CmpStr($$)
{
    my ($s1,$s2)  =@_;
    if ("$s1" lt "$s2")
    {
        return -1;
    }
    elsif ("$s1" gt "$s2")
    {
        return 1;
    }

    return 0;
}

sub Usage($)
{
    my ($exitcode)=@_;
    my ($fp);
    $fp = STDERR;
    if ($exitcode==0)
    {
        $fp = STDOUT;
    }

    print $fp "dirsha [-f compfile] dir \@filters\n";
    print $fp "-f compfile to compare the sha file\n";
    print $fp "-v for verbose mode\n";
    print $fp "-V for display version\n";
    exit($exitcode);
}

sub DirDiff($$@)
{
    my ($fdir,$rfd,@sortfiles)=@_;
    my ($curfile,$curdigest,$curline);
    my ($cont);
    my ($err,$rlines);
    my ($shadir);
    my ($content,$totalcount,$curcount,$percent,@rsarray,$curpercent,$lastcount);
    my ($perlen,$perstr);
    my ($_b);

    $perlen = 0;
    $perstr = "";

#DebugString("sortfiles @sortfiles\n");
    undef($curfile);
    undef($curdigest);
    undef($err);
    $shadir = ShaDir->new();
    $shadir->SetDir($fdir);
    $shadir->SetFiles(@sortfiles);
    $shadir->PrepareInit();
    $rlines = 0;
# we pretend to be continued
    $cont = 1;

	while(<$rfd>)
	{
		$curline=$_;
		if ($curline =~ m#^RS #o)
		{
			last;
		}
	}

	@rsarray = split(/ /,$curline);
	$totalcount = $rsarray[1];
	$curcount = 0;
	$percent = 0.0;
	$lastcount = $curcount;
#	DebugString("TotalCount $totalcount");
    
    print "AS $fdir\n";
    
    while(<$rfd>)
    {
        $curline = $_;
        chomp($curline);
#        DebugString("curline $curline");
        $rlines ++;
#DebugString("curline[$rlines] $curline\n");
        if ($curline =~ m#^F #o)
        {
            if (defined($curfile))
            {
# now it suppose it is the directory
                do
                {
                    #DebugString(" Curfile $curfile\n");
                    ($content,$cont) = $shadir->GetCmpString($curfile);
                    if (defined($content))
                    {
                        print "$content";
                    }
                }
                while ($cont);
            }
            $curfile = $curline;
            $curfile =~ s#^F ##;
#DebugString("curfile $curfile\n");
            $curcount ++;
        }
        elsif ($curline =~ m#^S #o)
        {
            $curdigest = $curline;
            $curdigest =~ s#^S ##;
        }
        elsif ($curline =~ m#^E #o)
        {
            $err = $curline;
            $err =~ s#^E ##;
        }
        elsif ($curline =~ m#^RE #o)
        {
# it means the last
#DebugString("\n");
            last;
        }

        if (defined($curfile) && defined($curdigest))
        {
# now to compare whether it is the one;
            do
            {
                ($content,$cont) = $shadir->GetCmpString($curfile,$curdigest);
                if (defined($content))
                {
                    print "$content";
                }
            }
            while ($cont);
            undef($curfile);
            undef($curdigest);

            $curpercent = $curcount / $totalcount;
#            DebugString("Percent $curpercent $percent\n");
            if ( ($curcount - $lastcount) > 100 &&  defined($opt_v))
            {
            	for ($_b = 0 ; $_b < $perlen ; $_b ++)
            	{
            		print STDERR "\b";
            	}
            	$perstr = "$curpercent";
            	$perlen = length($perstr);
            	print STDERR "$perstr";
            	$lastcount = $curcount;
            }
        }
        elsif (defined($curfile) && defined($err))
        {
# we do not see any of this error
            undef($curfile);
            undef($err);
        }
    } # end of while<$rfd>
#it is the last one,so we do this
# it must be the directory
    if (defined($curfile))
        {
            DebugString("curfile $curfile");
            do
            {
                ($content,$cont)=$shadir->GetCmpString($curfile);
                if (defined($content))
                {
                    print "$content";
                }
            }
            while($cont);
        }

    do
    {
        ($content,$cont) = $shadir->GetCmpString();
        if (defined($content))
        {
            print "$content";
        }
#DebugString("count $count\n");
    }
    while($cont);

    if (defined($opt_v))
    {
    	for ($_b=0;$_b < $perlen ; $_b++)
    	{
    		print STDERR "\b";
    	}
    	#print STDERR "\n";
    	#print STDERR "last($perstr) $perlen\n";
    	print STDERR "100.00\n";
    }

    print "AE $fdir\n";
}

sub FileSha($$)
{
    my ($fdir,$outname) =@_;
    my ($digest,$fname);

    if (length($outname) == 0)
    {
        return 0;
    }
    $fname = "$fdir"."/$outname";
    if ( -f $fname )
    {
        $digest = GetSha($fdir,$outname);
        print "F $outname\n";
        print "S $digest\n";
    }
    elsif ( -d $fname )
    {
        print "F $outname\n";
    }
    else
    {
        if ( -e $fname )
        {
            print "F $outname\n";
            print "E exist but not regular file or dir\n";
        }
        else
        {
            print "F $outname\n";
            print "E not exist\n";
        }
    }
    return 1;
}

sub DirSha($$)
{
    my ($fdir,$inf)=@_;
    my ($curline,$curfile);
    my ($files);

# sha start
    $files = 0;
    print "SS $fdir\n";
    while(<$inf>)
    {
        $curline = $_;
        chomp($curline);
        undef($curfile);
        if ($curline =~ m#^\+ #o)
        {
            $curfile = $curline;
            $curfile =~ s#^\+ ##;
        }
        elsif ( $curline =~ m#^M #o )
        {
            $curfile = $curline;
            $curfile =~ s#^M ##;
        }
        elsif ( $curline =~ m#^[A-Z]E #o )
        {
        	# it indicates the end
        	last;
        }

        if (defined($curfile))
        {
            $files += FileSha($fdir,$curfile);
        }
    }
#sha end
    print "SE $files $fdir\n";
    return $files;
}



getopts("hf:s:vV");

my ($cmpdir)=shift @ARGV;
my ($rdfile);
my ($rdfd);
@filters = @ARGV;
my (@wantsortfiles,@g_sortfiles);



if (defined($opt_h))
{
    Usage(0);
}

if (defined($opt_V))
{
	print STDOUT "$0 version 0.0.1\n";
	exit 0;
}

if (defined($opt_f))
{
    $rdfile = $opt_f;
}

if (!defined($cmpdir))
{
    Usage(3);
}

#DebugString("\n");
STDIN->autoflush(1);
STDOUT->autoflush(1);


if ($opt_f)
{
    my ($curlocaldir);
    find(\&DirFilter,$cmpdir);
    @wantsortfiles=TranslateFile($cmpdir,@rawfiles);
    @g_sortfiles = sort @wantsortfiles;

# to make the things right and delete the first '/'at the begin
    if ( "$opt_f" eq "-")
    {
        $rdfd = STDIN;
    }
    else
    {
#DebugString("Open $opt_f\n");
        open($rdfd,"<$opt_f") || die "can not open $opt_f for compare\n";
    }
    
    DirDiff($cmpdir,$rdfd,@g_sortfiles);

# now to close the rdfd
    if (fileno($rdfd) != fileno(STDIN))
    {
        close($rdfd);
    }
    $rdfd = undef;
}
elsif (defined($opt_s))
{
    if ("$opt_s" eq "-")
    {
        $rdfd = STDIN;
    }
    else
    {
        open($rdfd,"<$opt_s") || die "can not open $opt_s for sha get\n";
    }

# now to get the dir sha
    DirSha($cmpdir,$rdfd);


    if (fileno($rdfd) != fileno(STDIN))
    {
        close($rdfd);
    }
    $rdfd = undef;
}
else
{

    my ($files,$shadir,$cont,$str);
    find(\&DirFilter,$cmpdir);
    @wantsortfiles=TranslateFile($cmpdir,@rawfiles);
    @g_sortfiles = sort @wantsortfiles;


    $shadir = ShaDir->new();
    $shadir->SetDir($cmpdir);
    $shadir->SetFiles(@g_sortfiles);
    $shadir->PrepareInit();

    print "RS $#g_sortfiles $cmpdir\n";
    $files=0;
    do
    {
        ($str,$cont) = $shadir->FormDigest();
        if (defined($str))
        {
            print "$str";
        }
    }
    while($cont);
    print "RE $files $cmpdir\n";
}


