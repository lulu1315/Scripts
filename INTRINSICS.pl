#!/usr/bin/perl
 
use Cwd;
use Env;
use Term::ANSIColor qw(:constants);
use Image::Magick;
#http://www.imagemagick.org/script/command-line-options.php
$HOSTNAME=`cat /etc/hostname`;chop $HOSTNAME;
$KDEVERSION=`lsb_release -c -s`;chop $KDEVERSION;
$GPUS=`nvidia-smi -L | wc -l`;chop $GPUS;
$GPUTYPE=`nvidia-smi -q -i 0 | grep "Product Name" | cut -d':' -f2 | cut -c 2-`;chop $GPUTYPE;
$script = $0;
@tmp=split(/\//,$script);
$scriptname=$tmp[$#tmp];
@tmp=split(/\./,$scriptname);
$scriptname=lc $tmp[0];
$CWD=getcwd;
#get project name
@tmp=split(/\//,$CWD);
$PROJECT=$tmp[$#tmp];
$userName =  $ENV{'USER'}; 
print BOLD BLUE "----------------------\n";print RESET;
print BOLD BLUE "user    : $userName\n";print RESET;
print BOLD BLUE "host    : $HOSTNAME\n";print RESET;
print BOLD BLUE "kde     : $KDEVERSION\n";print RESET;
print BOLD BLUE "gpu     : $GPUTYPE (x$GPUS)\n";print RESET;
print BOLD BLUE "script  : $scriptname\n";print RESET;
print BOLD BLUE "project : $PROJECT\n";print RESET;
print BOLD BLUE "----------------------\n";print RESET;

#defaults
$FSTART="auto";
$FEND="auto";
$INDIR="$CWD/originales";
$IN="ima";
$OUTDIR="$CWD/intrinsics";
$OUT="ima";
$ZEROPAD=1;
$FORCE=0;
$EXT="png";
$VERBOSE=0;
$SHAVEX=2;
$SHAVEY=2;
$RESIZE=1;

sub verbose {
    if ($VERBOSE) {print BOLD GREEN "@_\n";print RESET}
}

sub isnum ($) {
#returns 0 if string 1 if number
#http://www.perlmonks.org/?node=How%20to%20check%20if%20a%20scalar%20value%20is%20numeric%20or%20string%3F
    return 0 if $_[0] eq '';
    $_[0] ^ $_[0] ? 0 : 1
}

sub confstr {
#format lines for autoconf
  ($str) = @_;
  if (isnum(${$str}))
    {$line="\$$str=${$str}\;\n";}
  else
    {$line="\$$str=\"${$str}\"\;\n";}
  return $line;
  }

sub autoconf {
open (AUTOCONF,">","$scriptname\_auto.conf");
print AUTOCONF confstr(PROJECT);
print AUTOCONF confstr(FSTART);
print AUTOCONF confstr(FEND);
print AUTOCONF confstr(INDIR);
print AUTOCONF confstr(IN);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(OUT);
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF confstr(SHAVEX);
print AUTOCONF confstr(SHAVEY);
print AUTOCONF confstr(RESIZE);
print AUTOCONF "1\n";
}

if ($#ARGV == -1) {
	print "usage: INTRINSICS_seq.pl \n";
	print "-autoconf\n";
	print "-conf file.conf\n";
	print "-f startframe endframe\n";
	print "-idir dirin\n";
	print "-i imagein\n";
	print "-odir dirout\n";
	print "-o imageout\n";
	print "-zeropad4 [1]\n";
	print "-force [0]\n";
	print "-verbose";
    print "-shavex [0]\n";
    print "-shavey [10]\n";
    print "-resize [.5]\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-autoconf") 
    {
    print "writing $scriptname\_auto.conf : mv $scriptname\_auto.conf $scriptname.conf \n";
    autoconf();
    if (-e "$OUTDIR") {print "$OUTDIR already exists\n";}
    else {$cmd="mkdir $OUTDIR";system $cmd;}
    exit;
    }
  if (@ARGV[$arg] eq "-conf") 
    {
    $CONF=@ARGV[$arg+1];
    print "using conf file $CONF\n";
    require "./$CONF";
    if (-e "$OUTDIR") {print "$OUTDIR already exists\n";}
    else {$cmd="mkdir $OUTDIR";system $cmd;}
    }
  if (@ARGV[$arg] eq "-f") 
    {
    $FSTART=@ARGV[$arg+1];
    $FEND=@ARGV[$arg+2];
    print "seq : $FSTART $FEND\n";
    }
  if (@ARGV[$arg] eq "-idir") 
    {
    $INDIR=@ARGV[$arg+1];
    print "in dir : $INDIR\n";
    }
  if (@ARGV[$arg] eq "-i") 
    {
    $IN=@ARGV[$arg+1];
    print "image in : $IN\n";
    }
  if (@ARGV[$arg] eq "-odir") 
    {
    $OUTDIR=@ARGV[$arg+1];
    print "out dir : $OUTDIR\n";
    }
  if (@ARGV[$arg] eq "-o") 
    {
    $OUT=@ARGV[$arg+1];
    print "image out : $OUT\n";
    }
  if (@ARGV[$arg] eq "-zeropad4") 
    {
    $ZEROPAD=1;
    print "zeropad4 ...\n";
    }
 if (@ARGV[$arg] eq "-force") 
    {
    $FORCE=1;
    print "force output ...\n";
    }
 if (@ARGV[$arg] eq "-verbose") 
    {
    $VERBOSE=1;
    print "force output ...\n";
    }
  if (@ARGV[$arg] eq "-shavex") 
    {
    $SHAVEX=@ARGV[$arg+1];
    print "shavex : $SHAVEX\n";
    }
  if (@ARGV[$arg] eq "-shavey") 
    {
    $SHAVEY=@ARGV[$arg+1];
    print "shavey : $SHAVEY\n";
    }
  if (@ARGV[$arg] eq "-resize") 
    {
    $RESIZE=@ARGV[$arg+1];
    print "resize : $RESIZE\n";
    }
  }
  
$userName =  $ENV{'USER'}; 
if ($userName eq "dev18")	#renderfarm
  {
  $INTRINSICS="/shared/foss-18/intrinsic/bell2014/decompose.py";
  $FORCE=1;
  }
if ($userName eq "render")	#renderfarm
  {
  $INTRINSICS="/home/render/intrinsic/bell2014/decompose.py";
  $FORCE=1;
  }
if ($userName eq "luluf")	#
  {
  $INTRINSICS="/home/luluf/intrinsic/bell2014/decompose.py";
  }
  
#auto frames
if ($FSTART eq "auto" || $FEND eq "auto")
    {
    #if ($IN_USE_SHOT) {$AUTODIR="$CONTENTDIR/$SHOT";} else {$AUTODIR="$CONTENTDIR";}
    $AUTODIR="$INDIR";
    print ("frames $FSTART $FEND dir $AUTODIR\n");
    opendir DIR, "$AUTODIR";
    @images = grep { /$IN/ && /$EXT/ } readdir DIR;
    closedir DIR;
    $min=9999999;
    $max=-1;
    foreach $ima (@images)
        {
        #print ("$ima\n");
        @tmp=split(/\./,$ima);
        if ($#tmp >= 2)
            {
            $numframe=int($tmp[$#tmp-1]);
            #print ("$numframe\n");
            if ($numframe > $max) {$max = $numframe;}
            if ($numframe < $min) {$min = $numframe;}
            }
        }

    if ($FSTART eq "auto") {$FSTART = $min;}
    if ($FEND   eq "auto") {$FEND   = $max;}
    print ("auto  seq : $min $max\n");
    print ("final seq : $FSTART $FEND\n");
    }
    
for ($i = $FSTART ;$i <= $FEND;$i++)
{
$ii=sprintf("%04d",$i);
print "image : $ii\n";
$IIN="$INDIR/$IN.$ii.png";
$OUTRESIZE="$OUTDIR/$OUT\_resize.$ii.png";
$OUTREFLECTANCE="$OUTDIR/$OUT\_reflectance.$ii.png";
$OUTSHADING="$OUTDIR/$OUT\_shading.$ii.png";

if (-e $OUTRESIZE && -e $OUTREFLECTANCE && -e $OUTSHADING && !$FORCE)
    {print RED "frames exists ... skipping\n";print RESET;}
else
    {
    #shave and resize input image
    $ioriginale = Image::Magick->new;
    $ioriginale->Read("$IIN");
    $resx = $ioriginale->[0]->Get('width');
    $resy = $ioriginale->[0]->Get('height');
    print "input resolution : $resx"."x"."$resy\n";
    $shavegeometry=$SHAVEX."x".$SHAVEY;
    $ioriginale->Shave(geometry=>$shavegeometry);
    $resx = $ioriginale->[0]->Get('width');
    $resy = $ioriginale->[0]->Get('height');
    print "aftershave resolution : $resx"."x"."$resy\n";
    #make sure res is of factor 2
    $rresx=int($resx*$RESIZE/2)*2;
    $rresy=int($resy*$RESIZE/2)*2;
    print "process resolution : $rresx"."x"."$rresy\n";
    $geometry=$rresx."x".$rresy;
    $ioriginale->Resize(geometry=>$geometry);
    $ioriginale->Write("$OUTRESIZE"); 
    if ($VERBOSE)
    {$cmd="$INTRINSICS $OUTRESIZE -s $OUTSHADING -r $OUTREFLECTANCE ";}#--quiet 2> intrinsics.log";
    else
    {$cmd="$INTRINSICS $OUTRESIZE -s $OUTSHADING -r $OUTREFLECTANCE --quiet 2> /var/tmp/intrinsics.log";}
    print "\n$cmd\n";
    #-----------------------------#
    ($s1,$m1,$h1)=localtime(time);
    #-----------------------------#
    system $cmd;
    #-----------------------------#
    ($s2,$m2,$h2)=localtime(time);
    ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
    print BOLD YELLOW "\nWriting  INTRINSIC $ii took $hlat:$mlat:$slat \n";
    print RESET;
    }
}

#-------------------------------------------------------#
#---------gestion des timecodes ------------------------#
#-------------------------------------------------------#
sub hmstoglob	{
my ($s,$m,$h) = @_;
my $glob;
#
$glob=$s+60*$m+3600*$h;
return $glob;
}

sub globtohms	{
my ($glob) = @_;
my $floath=$glob/3600;
my $h=int($floath);
#
my $reste=$glob-3600*$h;
my $floatm=$reste/60;
my $m=int($floatm);
#
my $s=$glob-3600*$h-60*$m;
#
return ($s,$m,$h);
}

sub timeplus  {
#($s,$m,$h)=timeplus($s1,$m1,$h1,$s2,$m2,$h2)
	my ($s1,$m1,$h1,$s2,$m2,$h2) = @_;
	$glob1=hmstoglob($s1,$m1,$h1);
	$glob2=hmstoglob($s2,$m2,$h2);
	$glob=$glob1+$glob2;
	($s,$m,$h) =globtohms($glob);
	return ($s,$m,$h);
}

sub lapse  {
#($s,$m,$h)=lapse($s1,$m1,$h1,$s2,$m2,$h2)
	my ($s1,$m1,$h1,$s2,$m2,$h2) = @_;
	$glob1=hmstoglob($s1,$m1,$h1);
	$glob2=hmstoglob($s2,$m2,$h2);
	if ($glob1 > $glob2)
		{
		$glob1=86400-$glob1;
		$glob=$glob2+$glob1;
		}
		else
		{
		$glob=$glob2-$glob1;
		}
#	print "$glob1 $glob2 $glob \n";
	my ($s,$m,$h) =globtohms($glob);
	return ($s,$m,$h);
}

