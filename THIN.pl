#!/usr/bin/perl

use Cwd;
use Env;
use Term::ANSIColor qw(:constants);
use Image::Magick;
#http://www.imagemagick.org/script/command-line-options.php
use List::Util qw(min max);
$script = $0;
print BOLD BLUE "script : $script\n";print RESET;
@tmp=split(/\//,$script);
$scriptname=$tmp[$#tmp];
@tmp=split(/\./,$scriptname);
$scriptname=lc $tmp[0];
$CWD=getcwd;
#get project name
@tmp=split(/\//,$CWD);
$PROJECT=$tmp[$#tmp];
print BOLD BLUE "project : $PROJECT\n";print RESET;

#defaults
$FSTART=1;
$FEND=100;
$INDIR="$CWD/edges";
$IN="edges_mx";
$COLORDIR="$CWD/originales";
$COLOR="ima";
$IN_USE_SHOT=0;
$SHOT="";
$OUTDIR="$CWD/thin";
$OUT="thin";
$ZEROPAD=1;
$FORCE=0;
$EXT="png";
$EXTIN="\$EXT";
$EXTOUT="\$EXT";
$VERBOSE=0;
#preprocess
$INSIZE=0;
$AUTOLEVEL=0;
$ROLLING=2;
$BRIGHTNESS=0;
#thin
$CONNEX=4;
#THINNING METHOD
$METHOD=3;
$LAMBDA=0;
$OTSU=8;
$OTSUGAIN=75;
$OTSUCONTRAST=0;
$OTSUGAMMA=0;
$TUFRADIUS=0;
$SKELMETHOD=25;
$SKELDILATE=3;
$DREAMSMOOTH=1;
$THRESHOLD=10;
#misc
$CLEAN=1;
$GPU=0;
$CSV=0;
$LOG1=">/var/tmp/$scriptname\_$GPU.log";
$LOG2="2>/var/tmp/$scriptname\_$GPU.log";

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
print AUTOCONF "reminder gradient methods\n";
print AUTOCONF "#1 : imagemagick canny\n";
print AUTOCONF "#2 : opencv canny\n";
print AUTOCONF "#3 : gmic edges\n";
print AUTOCONF "#4 : hed\n";
print AUTOCONF "#5 : pink canny deriche\n";
print AUTOCONF "#6 : gmic gradient norm\n";
print AUTOCONF "#7 : pink watershed\n";
print AUTOCONF confstr(INDIR);
print AUTOCONF confstr(IN);
print AUTOCONF confstr(IN_USE_SHOT);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(OUT);
print AUTOCONF confstr(SHOT);
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(EXTIN);
print AUTOCONF confstr(EXTOUT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF "#preprocess\n";
print AUTOCONF confstr(INSIZE);
print AUTOCONF confstr(AUTOLEVEL);
print AUTOCONF confstr(ROLLING);
print AUTOCONF confstr(BRIGHTNESS);
print AUTOCONF "#thin\n";
print AUTOCONF confstr(CONNEX);
print AUTOCONF confstr(METHOD);
print AUTOCONF "#-------------method 0 : all methods\n";
print AUTOCONF "#-------------method 1 : htkern\n";
print AUTOCONF "#-------------method 2 : lvkern\n";
print AUTOCONF "#-------------method 3 : ozu + skelpar [use parameter otsu(int)]\n";
print AUTOCONF "#-------------method 4 : lambdathin [use parameter lambda(int)]\n";
print AUTOCONF confstr(OTSU);
print AUTOCONF confstr(OTSUGAIN);
print AUTOCONF confstr(OTSUCONTRAST);
print AUTOCONF confstr(OTSUGAMMA);
print AUTOCONF confstr(TUFRADIUS);
print AUTOCONF confstr(SKELMETHOD);
print AUTOCONF confstr(SKELDILATE);
print AUTOCONF confstr(DREAMSMOOTH);
print AUTOCONF confstr(LAMBDA);
print AUTOCONF confstr(THRESHOLD);
print AUTOCONF "#misc\n";
print AUTOCONF confstr(CLEAN);
print AUTOCONF confstr(GPU);
print AUTOCONF confstr(CSV);
print AUTOCONF "1\n";
}

if ($#ARGV == -1) {
	print "usage: $scriptname.pl \n";
	print "-autoconf\n";
	print "-conf file.conf\n";
	print "-f startframe endframe\n";
	print "-idir dirin\n";
	print "-i imagein\n";
	print "-odir dirout\n";
	print "-o imageout\n";
	print "-zeropad4 [1]\n";
	print "-force [0]\n";
	print "-verbose\n";
	print "-gpu [0]\n";
	print "-csv csv_file.csv\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-autoconf") 
    {
    print "writing $scriptname\_auto.conf --> mv $scriptname\_auto.conf $scriptname.conf\n";
    autoconf();
    exit;
    }
  if (@ARGV[$arg] eq "-conf") 
    {
    $CONF=@ARGV[$arg+1];
    print BOLD BLUE "configuration file : $CONF\n";print RESET;
    require $CONF;
    if (-e "$OUTDIR") {print "$OUTDIR already exists\n";}
    else {$cmd="mkdir $OUTDIR";system $cmd;}
    }
  if (@ARGV[$arg] eq "-f") 
    {
    $FSTART=@ARGV[$arg+1];
    $FEND=@ARGV[$arg+2];
    print BOLD BLUE "seq : $FSTART $FEND\n";print RESET;
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
    $LOG1="";
    $LOG2="";
    print "verbose ...\n";
    }
  if (@ARGV[$arg] eq "-gpu") 
    {
    $GPU=@ARGV[$arg+1];
    print "gpu id : $GPU\n";
    }
  if (@ARGV[$arg] eq "-csv") 
    {
    $CSVFILE=@ARGV[$arg+1];
    print "csv file : $CSVFILE\n";
    $CSV=1;
    }
  }
  
$userName =  $ENV{'USER'}; 
if ($userName eq "dev" || $userName eq "render")	#
  {
  $GMIC="/usr/bin/gmic";
  $PINKBIN="/shared/foss/Pink/linux/bin";
  }
  
if ($userName eq "lulu")	#
  {
  $GMIC="/usr/bin/gmic";
  $PINKBIN="/shared/foss/Pink/linux/bin";
  }
  
if (-e "$OUTDIR") {print "$OUTDIR already exists\n";}
else {$cmd="mkdir $OUTDIR";system $cmd;}

if ($VERBOSE) {$LOG1="";$LOG2="";}

sub csv {
for ($i = $FSTART ;$i <= $FEND;$i++)
{
$ii=sprintf("%04d",$i);
if ($IN_USE_SHOT)
    {
    $IIN="$INDIR/$SHOT/$IN.$ii.$EXT";
    }
else
    {
    $IIN="$INDIR/$IN.$ii.$EXT";
    }
#outdir
$OOUTDIR="$OUTDIR/$SHOT";
if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
else {$cmd="mkdir $OOUTDIR";system $cmd;}

#preprocess and workdir
$WORKDIR="$OOUTDIR/w$ii";
#tested final frame
if ($METHOD)
    {$OOUT="$OOUTDIR/$OUT\_m$METHOD.$ii.$EXT";}
else
    {$OOUT="$OOUTDIR/$OUT\_m1.$ii.$EXT";}

if (-e $OOUT && !$FORCE)
    {print BOLD RED "frame $OOUT exists ... skipping\n";print RESET;}
else
  {
  #touch file
  $touchcmd="touch $OOUT";
  verbose($touchcmd);
  system $touchcmd;
  if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
  print BOLD YELLOW ("\nprocessing frame $ii\n");print RESET;
  #-----------------------------#
  ($s1,$m1,$h1)=localtime(time);
  #-----------------------------#
  $I=1;
    if ($ROLLING) 
        {$GMIC2="-fx_sharp_abstract $ROLLING,10,0.5,0,0";} 
    else {$GMIC2="";}
    if ($BRIGHTNESS) 
        {$GMIC3="-fx_adjust_colors $BRIGHTNESS,0,0,0,0 -n 0,255";} 
        #{$GMIC3="-mul $BRIGHTNESS";} 
    else {$GMIC3="";}
    if ($iNSIZE) 
        {$GMIC4="-resize2dx $iNSIZE,5";} 
  $cmd="$GMIC -i $IIN $GMIC4 $GMIC2 $GMIC3 -o $WORKDIR/$I.pgm $LOG2";
  verbose($cmd);
  print("--------> preprocess input [size:$INSIZE rolling:$ROLLING brightness:$BRIGHTNESS]\n");
  system $cmd;
  #if ($AUTOLEVEL)
    #{$AUTOLEVELCMD="-auto-level";
    #print("--------> autolevel input\n");
    #} else {$AUTOLEVELCMD="";}
  #$cmd="convert $IIN -colorspace gray $AUTOLEVELCMD $WORKDIR/$I.pgm $LOG2";
  #verbose($cmd);
  #system $cmd;
  $IIN="$WORKDIR/$I.pgm";
  #
  if (($METHOD == 1) || ($METHOD == 0))
  {
  $OOUT="$OOUTDIR/$OUT\_m1.$ii.$EXT";
  $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
  $cmd="$PINKBIN/htkern $IIN null $CONNEX $POUT";
  verbose($cmd);
  print("--------> htkern [connex:$CONNEX]\n");
  system $cmd;
  #
  $cmd="$GMIC -i $POUT -to_colormode 1 -o $OOUT $LOG2";
  verbose($cmd);
  system $cmd;
  #
  $MINIMA="$OOUTDIR/$OUT\_m1_minima.$ii.$EXT";
  $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
  $cmd="$PINKBIN/minima $PIN $CONNEX $POUT";
  verbose($cmd);
  print("--------> minima\n");
  system $cmd;
  #--> output minima
  $cmd="$GMIC -i $POUT -to_colormode 1 -o $MINIMA $LOG2";
  verbose($cmd);
  system $cmd;
  #
  }
  if (($METHOD == 2) || ($METHOD == 0))
  {
  $OOUT="$OOUTDIR/$OUT\_m2.$ii.$EXT";
  $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
  $cmd="$PINKBIN/lvkern $IIN null $CONNEX $POUT";
  verbose($cmd);
  print("--------> lvkern [connex:$CONNEX]\n");
  system $cmd;
  #
  $cmd="$GMIC -i $POUT -to_colormode 1 -o $OOUT $LOG2";
  verbose($cmd);
  system $cmd;
  #
  $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
  $cmd="$GMIC $PIN -threshold $THRESHOLD,1 -o $POUT $LOG2";
  verbose($cmd);
  print("--------> threshold [threshold:$THRESHOLD]\n");
  system $cmd;
  #minima
  $MINIMA="$OOUTDIR/$OUT\_m2_minima.$ii.$EXT";
  $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
  $cmd="$PINKBIN/minima $PIN $CONNEX $POUT";
  verbose($cmd);
  print("--------> minima\n");
  system $cmd;
  #--> output minima
  $cmd="$GMIC -i $POUT -to_colormode 1 -o $MINIMA $LOG2";
  verbose($cmd);
  system $cmd;
  #barycentre
  $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
  $cmd="$PINKBIN/barycentre $PIN $CONNEX $POUT";
  verbose($cmd);
  print("--------> barycentre [connex:$CONNEX]\n");
  system $cmd;
  #make hint
  $CCOLOR="$COLORDIR/$COLOR.$ii.$EXT";
  $HINT="$OOUTDIR/$OUT\_m2_hint.$ii.$EXT";
  $cmd="$GMIC $CCOLOR $POUT -split[0] c -append c -o $HINT $LOG2";
  #-n[1] 0,1 -oneminus[1] -n[1] 0,255
  verbose($cmd);
  print("--------> hint\n");
  system $cmd;
  #
  }
  #
  if (($METHOD == 3) || ($METHOD == 0))
  {
  $OOUT="$OOUTDIR/$OUT\_m3.$ii.$EXT";
  #do otsu binarisation
  $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
  #$cmd="$PINKBIN/seuilauto $PIN $SMOOTH max $POUT";
  #$cmd="$PINKBIN/seuil $PIN 1 $POUT";
  if ($OTSUGAIN || $OTSUCONTRAST || $OTSUGAMMA) 
    {$GMICOTSU="-fx_adjust_colors $OTSUGAIN,$OTSUCONTRAST,$OTSUGAMMA,0,0";} 
  $cmd="$GMIC $IIN $GMICOTSU -otsu $OTSU -n 0,255 -o $POUT $LOG2";
  verbose($cmd);
  print("--------> otsu binarisation [otsu:$OTSU]\n");
  system $cmd;
  #do tuf filtering
  if ($TUFRADIUS)
    {
    $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$PINKBIN/tuf $PIN $CONNEX $TUFRADIUS $POUT";
    verbose($cmd);
    print("--------> tuf filter [radius:$TUFRADIUS]\n");
    system $cmd;
    }
  #do euclidian skeleton
  $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
  $cmd="$PINKBIN/skelpar $PIN $SKELMETHOD -1 $POUT";
  verbose($cmd);
  print("--------> skelpar [method:$SKELMETHOD]\n");
  system $cmd;
  #dreamsmooth
  if ($DREAMSMOOTH)
    {
    $GMICSMOOTH="-fx_dreamsmooth 10,0,1,0.8,0,0.8,0,24,0";
    print("--------> dreamsmooth\n");
    } else {$GMICSMOOTH="";}
  $cmd="$GMIC -i $POUT -dilate $SKELDILATE $GMICSMOOTH -to_colormode 1 -o $OOUT $LOG2";
  verbose($cmd);
  system $cmd;
  }
  if (($METHOD == 4) || ($METHOD == 0))
  {
  $OOUT="$OOUTDIR/$OUT\_m4.$ii.$EXT";
  $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
  $cmd="$PINKBIN/lambdathin $IIN null -1 $CONNEX $LAMBDA $POUT $LOG2";
  verbose($cmd);
  print("--------> lambdathin [lambda:$LAMBDA connex:$CONNEX]\n");
  system $cmd;
  #
  $cmd="$GMIC -i $POUT -to_colormode 1 -o $OOUT $LOG2";
  verbose($cmd);
  system $cmd;
  #
  $MINIMA="$OOUTDIR/$OUT\_m4_minima.$ii.$EXT";
  $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
  $cmd="$PINKBIN/minima $PIN $CONNEX $POUT";
  verbose($cmd);
  print("--------> minima\n");
  system $cmd;
  #--> output minima
  $cmd="$GMIC -i $POUT -to_colormode 1 -o $MINIMA $LOG2";
  verbose($cmd);
  system $cmd;
  }
  #clean
  if ($CLEAN)
    {
    $cleancmd="rm -r $WORKDIR";
    verbose($cleancmd);
    system $cleancmd;
    }
  #-----------------------------#
  ($s2,$m2,$h2)=localtime(time);
  ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
  print BOLD YELLOW "Writing $OOUTDIR/$OUT.$ii.$EXT took $hlat:$mlat:$slat\n";print RESET;
  #-----------------------------#
  }
}
}#end csv

#main
if ($CSV)
  {
  open (CSV , "$CSVFILE");
  while ($line=<CSV>)
    {
    chop $line;
    @line=split(/,/,$line);
    $SHOT=@line[0];
    $FSTART=@line[3];
    $FEND=@line[4];
    $LENGTH=@line[5];   
    $process=@line[6];
    if ($process)
      {
      csv();
      }
    }
   }
else
  {
  csv();
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
