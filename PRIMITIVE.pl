#!/usr/bin/perl
 
use Cwd;
use Env;
use Term::ANSIColor qw(:constants);
use List::Util qw(max min);
use Image::Magick;
#http://www.imagemagick.org/script/command-line-options.php
$script = $0;
print BOLD BLUE "script : $script\n";print RESET;
@tmp=split(/\//,$script);
$scriptname=$tmp[$#tmp];
$CWD=getcwd;
#get project name
@tmp=split(/\//,$CWD);
$PROJECT=$tmp[$#tmp];
print BOLD BLUE "project : $PROJECT\n";print RESET;

#defaults
$FSTART=1;
$FEND=2;
$FSTEP=1;
$INDIR="$CWD/originales";
$IN="ima";
$OUTDIR="$CWD/primitive";
$OUT="prim";
$ZEROPAD=1;
$FORCE=0;
$EXT="png";
$VERBOSE=0;
$NSHAPES=100;
$SHAPE=0;
$REP=0;
$RESIZE=256;
$ALPHA=128;
$PARAMS="n$NSHAPES\_m$SHAPE";
$OUTSIZE=0;
$PLY=1;

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
open (AUTOCONF,">","primitive_auto.conf");
print AUTOCONF confstr(PROJECT);
print AUTOCONF confstr(FSTART);
print AUTOCONF confstr(FEND);
print AUTOCONF confstr(FSTEP);
print AUTOCONF confstr(INDIR);
print AUTOCONF confstr(IN);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(OUT);
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF confstr(NSHAPES);
print AUTOCONF confstr(SHAPE);
print AUTOCONF "#0=combo 1=triangle 2=rect 3=ellipse 4=circle 5=rotatedrect 6=beziers 7=rotatedellipse\n";
print AUTOCONF confstr(REP);
print AUTOCONF confstr(RESIZE);
print AUTOCONF confstr(ALPHA);
print AUTOCONF confstr(OUTSIZE);
print AUTOCONF confstr(PLY);
print AUTOCONF "\$PARAMS=\"n\$NSHAPES\\_m\$SHAPE\";\n";
print AUTOCONF "1\n";
}

if ($#ARGV == -1) {
	print "usage: PRIMITIVE.pl \n";
	print "-autoconf\n";
	print "-conf file.conf\n";
	print "-f startframe endframe\n";
	print "-step step[1]\n";
	print "-idir dirin\n";
	print "-i imagein\n";
	print "-odir dirout\n";
	print "-o imageout\n";
	print "-e image ext (png)\n";
	print "-r resize [256]\n";
	print "-n nshapes [100]\n";
	print "-rep repetition [0]\n";
	print "-m shape [0] : 0=combo 1=triangle 2=rect 3=ellipse 4=circle 5=rotatedrect 6=beziers 7=rotatedellipse\n";
	print "-a alpha [128]\n";
	print "-zeropad4\n";
	print "-force\n";
	print "-verbose [0]\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-autoconf") 
    {
    print "writing auto.conf\n";
    autoconf();
    if (-e "$OUTDIR") {print "$OUTDIR already exists\n";}
    else {$cmd="mkdir $OUTDIR";system $cmd;}
    exit;
    }
  if (@ARGV[$arg] eq "-conf") 
    {
    $CONF=@ARGV[$arg+1];
    print "using conf file $CONF\n";
    require $CONF;
    }
  if (@ARGV[$arg] eq "-f") 
    {
    $FSTART=@ARGV[$arg+1];
    $FEND=@ARGV[$arg+2];
    print "seq : $FSTART $FEND\n";
    }
  if (@ARGV[$arg] eq "-step") 
    {
    $FSTEP=@ARGV[$arg+1];
    print "step $FSTEP\n";
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
  if (@ARGV[$arg] eq "-e") 
    {
    $EXT=@ARGV[$arg+1];
    print "ext : $EXT\n";
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
  if (@ARGV[$arg] eq "-r") 
    {
    $RESIZE=@ARGV[$arg+1];
    print "resize : $RESIZE\n";
    }
  if (@ARGV[$arg] eq "-n") 
    {
    $NSHAPES=@ARGV[$arg+1];
    print "nshapes : $NSHAPES\n";
    }
  if (@ARGV[$arg] eq "-m") 
    {
    $SHAPE=@ARGV[$arg+1];
    print "shape : $SHAPE\n";
    }
  if (@ARGV[$arg] eq "-rep") 
    {
    $REP=@ARGV[$arg+1];
    print "repetition : $REP\n";
    }
  if (@ARGV[$arg] eq "-a") 
    {
    $ALPHA=@ARGV[$arg+1];
    print "color alpha : $ALPHA\n";
    }
  if (@ARGV[$arg] eq "-verbose") 
    {
    $VERBOSE=1;
    }
  }
  
  
$userName =  $ENV{'USER'}; 
if ($userName eq "dev" || $userName eq "render")	#
  {
  $GMIC="/shared/foss/gmic/src/gmic";
  $PRIMITIVE="/shared/foss/go/gowork/bin/primitive_with_ply";
  }
if ($userName eq "lulu")	#a Nanterre
  {
  $GMIC="/shared/foss/gmic/src/gmic";
  $PRIMITIVE="/home/luluf/gowork/bin/primitive_with_ply";
  }
  
#$PARAMS="n$NSHAPES\_m$SHAPE";

for ($i = $FSTART ;$i <= $FEND; $i=$i+$FSTEP)
{
#-----------------------------#
($s1,$m1,$h1)=localtime(time);
#-----------------------------#

$ii=sprintf("%04d",$i);
$IIN="$INDIR/$IN.$ii.$EXT";
$OOUT="$OUTDIR/$OUT\_$PARAMS.$ii.$EXT";
#
if ($PLY)
  {
  $OOUTPLY="$OUTDIR/$OUT\_$PARAMS.$ii.ply";
  }

if (-e $OOUT && !$FORCE)
  {print BOLD RED "frame $OOUT exists ... skipping\n";print RESET;}
else
  {
  #touch file
  $touchcmd="touch $OOUT";
  verbose($touchcmd);
  system $touchcmd;
  if ($OUTSIZE)
    {$OUTRESIZE=$OUTSIZE;}
  else
    {
    #get input size
    $imagein = Image::Magick->new;
    $imagein->Read("$IIN");
    $resx = $imagein->[0]->Get('width');
    $resy = $imagein->[0]->Get('height');
    verbose("output resolution : $resx"."x"."$resy");
    $OUTRESIZE=max($resx,$resy);
    }
if ($PLY)
  {
  if ($VERBOSE)
    {$cmd="$PRIMITIVE -i $IIN -o $OOUT -o $OOUTPLY -n $NSHAPES -m $SHAPE -rep $REP -r $RESIZE -v -a $ALPHA -s $OUTRESIZE";}
  else
    {$cmd="$PRIMITIVE -i $IIN -o $OOUT -o $OOUTPLY -n $NSHAPES -m $SHAPE -rep $REP -r $RESIZE -a $ALPHA -s $OUTRESIZE";}
  verbose($cmd);
  system $cmd;
  }
else
  {
  if ($VERBOSE)
    {$cmd="$PRIMITIVE -i $IIN -o $OOUT -n $NSHAPES -m $SHAPE -rep $REP -r $RESIZE -v -a $ALPHA -s $OUTRESIZE";}
  else
    {$cmd="$PRIMITIVE -i $IIN -o $OOUT -n $NSHAPES -m $SHAPE -rep $REP -r $RESIZE -a $ALPHA -s $OUTRESIZE";}
  verbose($cmd);
  system $cmd;
  }
  #-----------------------------#
  ($s2,$m2,$h2)=localtime(time);
  ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
  print BOLD YELLOW "Writing $OOUT took $hlat:$mlat:$slat \n";print RESET;
  #-----------------------------#
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
