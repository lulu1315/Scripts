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
$CWD=getcwd;
#get project name
@tmp=split(/\//,$CWD);
$PROJECT=$tmp[$#tmp];
print BOLD BLUE "project : $PROJECT\n";print RESET;

#defaults
$FSTART=1;
$FEND=100;
$INDIR="$CWD/originales";
$IN="ima";
$IN_USE_SHOT=0;
$SHOT="";
$OUTDIR="$CWD/gradthin";
$OUT="gradthin";
$ZEROPAD=1;
$FORCE=0;
$EXT="png";
$EXTIN="\$EXT";
$EXTOUT="\$EXT";
$VERBOSE=0;
#HED
$INSIZE=960;
#GRADIENT METHOD
$GRADIENT=1;
$AUTOLEVEL=1;
$ALPHA=.5;
$CONNEX=4;
#THINNING METHOD
$METHOD=3;
$LAMBDA=0;
$OTSU=8;
$OTSUGAIN=100;
$OTSUCONTRAST=0;
$OTSUGAMMA=0;
$TUFRADIUS=0;
$SKELMETHOD=25;
$SKELDILATE=3;
$DREAMSMOOTH=1;
$DOWATERSHED=1;
$DOMINIMA=0;
#preprocess
$COLORMODEL="rgb";
$DOLOCALCONTRAST=1;
$ROLLING=2;
$BRIGHTNESS=0;
$CONTRAST=0;
$GAMMA=0;
$SATURATION=0;
$CLEAN=1;
$GPU=0;
$CSV=0;
$LOG1=">/var/tmp/gradthin_$GPU.log";
$LOG2="2>/var/tmp/gradthin_$GPU.log";

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
open (AUTOCONF,">","gradthin_auto.conf");
print AUTOCONF confstr(PROJECT);
print AUTOCONF confstr(FSTART);
print AUTOCONF confstr(FEND);
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
print AUTOCONF "#-------------hed\n";
print AUTOCONF confstr(INSIZE);
print AUTOCONF confstr(GRADIENT);
print AUTOCONF confstr(AUTOLEVEL);
print AUTOCONF "#-------------gradient=1 = Canny-Deriche [use parameter alpha(int)]\n";
print AUTOCONF confstr(ALPHA);
print AUTOCONF "#-------------gradient=2 = gradient_norm\n";
print AUTOCONF "#-------------gradient=3 = HED\n";
print AUTOCONF confstr(CONNEX);
print AUTOCONF confstr(METHOD);
print AUTOCONF "#-------------method 0 : all methods\n";
print AUTOCONF "#-------------method 1 : htkern\n";
print AUTOCONF "#-------------method 2 : lvkern\n";
print AUTOCONF "#-------------method 3 : ozu + skeleucl [use parameter otsu(int)]\n";
print AUTOCONF confstr(OTSU);
print AUTOCONF confstr(OTSUGAIN);
print AUTOCONF confstr(OTSUCONTRAST);
print AUTOCONF confstr(OTSUGAMMA);
print AUTOCONF confstr(TUFRADIUS);
print AUTOCONF confstr(SKELMETHOD);
print AUTOCONF confstr(SKELDILATE);
print AUTOCONF confstr(DREAMSMOOTH);
print AUTOCONF "#-------------method 4 : lambdathin [use parameter lambda(int)]\n";
print AUTOCONF confstr(LAMBDA);
print AUTOCONF "#-------------wshedtopo\n";
print AUTOCONF confstr(DOWATERSHED);
print AUTOCONF confstr(DOMINIMA);
print AUTOCONF "#-------------preprocess\n";
print AUTOCONF confstr(COLORMODEL);
print AUTOCONF "#-------------rgb : luminance\n";
print AUTOCONF "#-------------hcy : keep chrominance[c]\n";
print AUTOCONF confstr(DOLOCALCONTRAST);
print AUTOCONF confstr(ROLLING);
print AUTOCONF confstr(BRIGHTNESS);
print AUTOCONF confstr(CONTRAST);
print AUTOCONF confstr(GAMMA);
print AUTOCONF confstr(SATURATION);
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
    print "writing gradthin_auto.conf --> mv gradthin_auto.conf gradthin.conf\n";
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
  $HED="python /shared/foss/hed/examples/hed/make_hed.py";
  $PINKBIN="/shared/foss/Pink/linux/bin";
  $ENV{PYTHONPATH} = "/shared/foss/hed/python:$ENV{'PYTHONPATH'}";
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
$FINALFRAME="$OOUTDIR/$OUT.$ii.$EXT";

if (-e $FINALFRAME && !$FORCE)
    {print BOLD RED "frame $FINALFRAME exists ... skipping\n";print RESET;}
else
  {
  #touch file
  $touchcmd="touch $FINALFRAME";
  verbose($touchcmd);
  system $touchcmd;
  if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
  print BOLD YELLOW ("\nprocessing frame $ii\n");print RESET;
  #-----------------------------#
  ($s1,$m1,$h1)=localtime(time);
  #-----------------------------#
  #--> preprocess
  if ($DOLOCALCONTRAST) 
    {$GMIC1="-fx_LCE[0] 80,0.5,1,1,0,0";} 
    else {$GMIC1="";}
  if ($ROLLING) 
    {$GMIC2="-fx_sharp_abstract $ROLLING,10,0.5,0,0";} 
    else {$GMIC2="";}
  if ($BRIGHTNESS || $CONTRAST || $GAMMA || $SATURATION) 
    {$GMIC3="-fx_adjust_colors $BRIGHTNESS,$CONTRAST,$GAMMA,0,$SATURATION";} 
    else {$GMIC3="";}
  if ($INSIZE) 
    {$GMIC4="-resize2dx $INSIZE,5";} 
    else {$GMIC4="";}
  $GMIC5="";
  if ($COLORMODEL eq "rgb") 
    {$GMIC5="-to_colormode 1";} 
  if ($COLORMODEL eq "hcy") 
    {$GMIC5="-rgb2hcy -split c -remove[0,2] -n 0,255";} 
  $I=1;
  if (($GRADIENT == 1) || ($GRADIENT == 2))
  {$cmd="$GMIC -i $IIN $GMIC4 $GMIC1 $GMIC2 $GMIC3 $GMIC5 -o $WORKDIR/$I.pgm $LOG2";}
  else
  {$cmd="$GMIC -i $IIN $GMIC4 $GMIC1 $GMIC2 $GMIC3 $GMIC5 -to_colormode 3 -o $WORKDIR/$I.pgm $LOG2";}
  verbose($cmd);
  system $cmd;
  #keep color
  $COLOR="$OOUTDIR/$OUT\_color.$ii.$EXT";
  $cmd="$GMIC $WORKDIR/1.pgm -o $COLOR $LOG2";
  verbose($cmd);
  system $cmd;
  #
  #work hed
  $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm"; # !! out = 2.tiff
  if ($GRADIENT == 1)
  {
  $cmd="$PINKBIN/gradientcd $PIN $ALPHA $POUT";
  print BOLD BLUE "--> using gradientcd\n";print RESET;
  verbose($cmd);
  system $cmd;
  #--> formatting gradient
  $cmd="$GMIC -i $POUT -to_colormode 3 -o $FINALFRAME $LOG2";
  verbose($cmd);
  system $cmd;
  #
  }
  if ($GRADIENT == 2)
  {
  $cmd="$GMIC $PIN -gradient_norm -o $POUT $LOG2";
  print BOLD BLUE "--> using gradient_norm\n";print RESET;
  verbose($cmd);
  system $cmd;
  #autolovel
  if ($AUTOLEVEL)
    {
    $cmd="convert $POUT -auto-level $POUT";
    verbose($cmd);
    system $cmd;
    }
  #--> formatting gradient
  $cmd="$GMIC -i $POUT -to_colormode 3 -o $FINALFRAME $LOG2";
  verbose($cmd);
  system $cmd;
  #
  }
  #
  if ($GRADIENT == 3)
  {
  $cmd="$HED --image_in $PIN --image_out=$POUT --gpu_id $GPU 2>/var/tmp/hed_$GPU.log";
  print BOLD BLUE "--> using hed\n";print RESET;
  verbose($cmd);
  system $cmd;
  #convert hed to pgm
  $cmd="$GMIC -i $WORKDIR/$I.tiff -mul 255 -to_colormode 1 -o $POUT $LOG2";
  verbose($cmd);
  system $cmd;
  if ($AUTOLEVEL)
    {
    $cmd="convert $POUT -auto-level $POUT";
    verbose($cmd);
    system $cmd;
    }
  #--> formatting hed
  $cmd="$GMIC $POUT -to_colormode 3 -o $FINALFRAME $LOG2";
  verbose($cmd);
  system $cmd;
  }
  #
  if (($METHOD == 1) || ($METHOD == 0))
  {
  $I=2;
  $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
  $cmd="$PINKBIN/htkern $PIN null $CONNEX $POUT";
  verbose($cmd);
  system $cmd;
  #
  $HTKERN="$OOUTDIR/$OUT\_htkern_connex$CONNEX.$ii.$EXT";
  $cmd="$GMIC -i $POUT -to_colormode 1 -o $HTKERN $LOG2";
  verbose($cmd);
  system $cmd;
  #
  if ($DOMINIMA)
    {
    $MINIMA="$OOUTDIR/$OUT\_htkern_connex$CONNEX\_minima.$ii.$EXT";
    $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$PINKBIN/minima $PIN $CONNEX $POUT";
    verbose($cmd);
    system $cmd;
    #--> output minima
    $cmd="$GMIC -i $POUT -to_colormode 1 -o $MINIMA $LOG2";
    verbose($cmd);
    system $cmd;
    }
  }
  if (($METHOD == 2) || ($METHOD == 0))
  {
  $I=2;
  $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
  $cmd="$PINKBIN/lvkern $PIN null $CONNEX $POUT";
  verbose($cmd);
  system $cmd;
  #
  $LVKERN="$OOUTDIR/$OUT\_lvkern_connex$CONNEX.$ii.$EXT";
  $cmd="$GMIC -i $POUT -to_colormode 1 -o $LVKERN $LOG2";
  verbose($cmd);
  system $cmd;
  #
  if ($DOMINIMA)
    {
    $MINIMA="$OOUTDIR/$OUT\_lvkern_connex$CONNEX\_minima.$ii.$EXT";
    $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$PINKBIN/minima $PIN $CONNEX $POUT";
    verbose($cmd);
    system $cmd;
    #--> output minima
    $cmd="$GMIC -i $POUT -to_colormode 1 -o $MINIMA $LOG2";
    verbose($cmd);
    system $cmd;
    }
  }
  #
  if (($METHOD == 3) || ($METHOD == 0))
  {
  $I=2;
  #do otsu binarisation
  $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
  #$cmd="$PINKBIN/seuilauto $PIN $SMOOTH max $POUT";
  #$cmd="$PINKBIN/seuil $PIN 1 $POUT";
  if ($OTSUGAIN || $OTSUCONTRAST || $OTSUGAMMA) 
    {$GMICOTSU="-fx_adjust_colors $OTSUGAIN,$OTSUCONTRAST,$OTSUGAMMA,0,0";} 
  $cmd="$GMIC $PIN $GMICOTSU -otsu $OTSU -n 0,255 -o $POUT $LOG2";
  verbose($cmd);
  system $cmd;
  #do tuf filtering
  if ($TUFRADIUS)
    {
    $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$PINKBIN/tuf $PIN $CONNEX $TUFRADIUS $POUT";
    verbose($cmd);
    system $cmd;
    }
  #keep otsu
  $OOTSU="$OOUTDIR/$OUT\_otsu_$OTSU.$ii.$EXT";
  $cmd="$GMIC -i $POUT -to_colormode 1 -o $OOTSU $LOG2";
  verbose($cmd);
  system $cmd;
  #do euclidian skeleton
  $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
  $cmd="$PINKBIN/skelpar $PIN $SKELMETHOD -1 $POUT";
  verbose($cmd);
  system $cmd;
  #keep euclidian skeleton
  $SKEL="$OOUTDIR/$OUT\_skel.$ii.$EXT";
  #dreamsmooth
  if ($DREAMSMOOTH)
    {$GMICSMOOTH="-fx_dreamsmooth 10,0,1,0.8,0,0.8,0,24,0";} else {$GMICSMOOTH="";}
  $cmd="$GMIC -i $POUT -dilate $SKELDILATE $GMICSMOOTH -to_colormode 1 -o $SKEL $LOG2";
  verbose($cmd);
  system $cmd;
  }
  if (($METHOD == 4) || ($METHOD == 0))
  {
  $I=2;
  $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
  $cmd="$PINKBIN/lambdathin $PIN null -1 $CONNEX $LAMBDA $POUT $LOG2";
  verbose($cmd);
  system $cmd;
  #
  $LAMBDATHIN="$OOUTDIR/$OUT\_lambdathin_connex$CONNEX.$ii.$EXT";
  $cmd="$GMIC -i $POUT -to_colormode 1 -o $LAMBDATHIN $LOG2";
  verbose($cmd);
  system $cmd;
  #
  if ($DOMINIMA)
    {
    $MINIMA="$OOUTDIR/$OUT\_lambdathin_connex$CONNEX\_minima.$ii.$EXT";
    $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$PINKBIN/minima $PIN $CONNEX $POUT";
    verbose($cmd);
    system $cmd;
    #--> output minima
    $cmd="$GMIC -i $POUT -to_colormode 1 -o $MINIMA $LOG2";
    verbose($cmd);
    system $cmd;
    }
  }
  #
  if ($DOWATERSHED)
  {
  $I=2;
  $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
  $cmd="$PINKBIN/wshedtopo $PIN $CONNEX $POUT";
  verbose($cmd);
  system $cmd;
  #
  $WSHED="$OOUTDIR/$OUT\_wshed_connex$CONNEX.$ii.$EXT";
  $cmd="$GMIC -i $POUT -to_colormode 1 -o $WSHED $LOG2";
  verbose($cmd);
  system $cmd;
  #
  if ($DOMINIMA)
    {
    $MINIMA="$OOUTDIR/$OUT\_wshed_connex$CONNEX\_minima.$ii.$EXT";
    $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$PINKBIN/minima $PIN $CONNEX $POUT";
    verbose($cmd);
    system $cmd;
    #--> output minima
    $cmd="$GMIC -i $POUT -to_colormode 1 -o $MINIMA $LOG2";
    verbose($cmd);
    system $cmd;
    }
  }
  #
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
