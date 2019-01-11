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
$EDGEDIR="$CWD/thin";
$CONNEX=8;
$EDGE="gradthin_wshed_connex$CONNEX";
$POTRACEDIR="$CWD/potrace";
$POTRACE="potrace";
$COLORDIR="$CWD/originales";
$COLOR="ima";
$IN_USE_SHOT=0;
$SHOT="";
$OUTDIR="$CWD/lineart";
$OUT="lineart";
$ZEROPAD=1;
$FORCE=0;
$EXT="png";
$EXTIN="\$EXT";
$EXTOUT="\$EXT";
$VERBOSE=0;
#lineart
$DOCOMPO=1;
$DREAMSMOOTH=0;
$DILATE=0;
$BLENDMODE="multiply";
$BLENDOPACITY=1;
#preprocess
$DOLOCALCONTRAST=1;
$ROLLING=4;
$BRIGHTNESS=0;
$CONTRAST=0;
$GAMMA=0;
$SATURATION=0;
$CLEAN=1;
$GPU=0;
$CSV=0;
$LOG1=">/var/tmp/lineart_$GPU.log";
$LOG2="2>/var/tmp/lineart_$GPU.log";

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
open (AUTOCONF,">","lineart_auto.conf");
print AUTOCONF confstr(PROJECT);
print AUTOCONF confstr(FSTART);
print AUTOCONF confstr(FEND);
print AUTOCONF confstr(EDGEDIR);
print AUTOCONF confstr(EDGE);
print AUTOCONF confstr(POTRACEDIR);
print AUTOCONF confstr(POTRACE);
print AUTOCONF confstr(COLORDIR);
print AUTOCONF confstr(COLOR);
print AUTOCONF confstr(IN_USE_SHOT);
print AUTOCONF confstr(SHOT);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(OUT);
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(EXTIN);
print AUTOCONF confstr(EXTOUT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF "#hed\n";
print AUTOCONF confstr(CONNEX);
print AUTOCONF confstr(DOCOMPO);
print AUTOCONF confstr(BLENDMODE);
print AUTOCONF confstr(BLENDOPACITY);
print AUTOCONF confstr(DREAMSMOOTH);
print AUTOCONF confstr(DILATE);
print AUTOCONF "#preprocess\n";
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
    print "writing lineart_auto.conf --> mv lineart_auto.conf lineart.conf\n";
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
  $GMIC="/shared/foss/gmic/src/gmic";
  $PINKBIN="/shared/foss/Pink/linux/bin";
  }
  
if ($userName eq "lulu")	#
  {
  $GMIC="/shared/foss/gmic/src/gmic";
  $PINKBIN="/shared/foss/Pink/linux/bin";
  }
  
if ($VERBOSE) {$LOG1="";$LOG2="";}

if (-e "$OUTDIR") {print "$OUTDIR already exists\n";}
else {$cmd="mkdir $OUTDIR";system $cmd;}

sub csv {
for ($i = $FSTART ;$i <= $FEND;$i++)
{
$ii=sprintf("%04d",$i);
#input
if ($IN_USE_SHOT)
    {
    $COLORS="$COLORDIR/$SHOT/$COLOR.$ii.$EXT";
    $EDGES="$EDGEDIR/$SHOT/$EDGE.$ii.$EXT";
    $POTRACES="$POTRACEDIR/$SHOT/$POTRACE.$ii.$EXT";
    }
else
    {
    $COLORS="$COLORDIR/$COLOR.$ii.$EXT";
    $EDGES="$EDGEDIR/$EDGE.$ii.$EXT";
    $POTRACES="$POTRACEDIR/$POTRACE.$ii.$EXT";
    }
#outdir
$OOUTDIR="$OUTDIR/$SHOT";
if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
else {$cmd="mkdir $OOUTDIR";system $cmd;}
#preprocess and workdir
$WORKDIR="$OOUTDIR/w$ii";
#tested final frame
$LINEART="$OOUTDIR/$OUT.$ii.$EXT";
$LINEART1="$OOUTDIR/$OUT\_fromhint.$ii.$EXT";
$HINT="$OOUTDIR/$OUT\_hint.$ii.$EXT";
$MINIMA="$OOUTDIR/$OUT\_minima.$ii.$EXT";
$COMPO="$OOUTDIR/$OUT\_compo.$ii.$EXT";

if (-e $LINEART && !$FORCE)
    {print BOLD RED "frame $LINEART exists ... skipping\n";print RESET;}
else
  {
  #touch file
  $touchcmd="touch $LINEART";
  verbose($touchcmd);
  system $touchcmd;
  if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
  print BOLD YELLOW ("\nprocessing frame $ii\n");print RESET;
  #-----------------------------#
  ($s1,$m1,$h1)=localtime(time);
  #-----------------------------#
  #--> match color with edge size
  if ($DOLOCALCONTRAST) 
    {$GMIC1="-fx_LCE[0] 80,0.5,1,1,0,0";} 
    else {$GMIC1="";}
  if ($ROLLING) 
    {$GMIC2="-fx_sharp_abstract[0] $ROLLING,10,0.5,0,0";} 
    else {$GMIC2="";}
  if ($BRIGHTNESS || $CONTRAST || $GAMMA || $SATURATION) 
    {$GMIC3="-fx_adjust_colors[0] $BRIGHTNESS,$CONTRAST,$GAMMA,0,$SATURATION";} 
    else {$GMIC3="";}
  $cmd="$GMIC $COLORS $EDGES -resize2dx {w},5 $GMIC1 $GMIC2 $GMIC3 -o[0] $WORKDIR/color.png $LOG2";
  verbose($cmd);
  print("--------> preprocess input [size:$SIZE lce:$DOLOCALCONTRAST rolling:$ROLLING bcgs:$BRIGHTNESS/$CONTRAST/$GAMMA/$SATURATION]\n");
  system $cmd;
  #prepare edges
  $I=1;
  #$cmd="$GMIC -i $EDGES -n 0,1 -oneminus -n 0,255 -to_colormode 1 -o $WORKDIR/$I.pgm $LOG2";
  $cmd="$GMIC -i $EDGES -to_colormode 1 -o $WORKDIR/$I.pgm $LOG2";
  verbose($cmd);
  system $cmd;
  #minima
  $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
  $cmd="$PINKBIN/minima $PIN $CONNEX $POUT";
  verbose($cmd);
  print("--------> minima\n");
  system $cmd;
  #keep minima
  $cmd="$GMIC -i $POUT -to_colormode 3 -o $MINIMA $LOG2";
  verbose($cmd);
  system $cmd;
  #
  #barycentre
  $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
  $cmd="$PINKBIN/barycentre $PIN $CONNEX $POUT";
  verbose($cmd);
  print("--------> barycentre\n");
  system $cmd;
  #make hint
  $cmd="$GMIC $WORKDIR/color.png $POUT -split[0] c -append c -o $HINT $LOG2";
  #-n[1] 0,1 -oneminus[1] -n[1] 0,255
  verbose($cmd);
  print("--------> color hint\n");
  system $cmd;
  #make lineart
  $cmd="$GMIC $MINIMA $WORKDIR/color.png -fx_colorize_lineart_smartcoloring 2,95,0,0,0,1,24,200,0,0,1,0,0,0,0,0,1,0,20,64,7.5,0.5,0 -o[1] $LINEART $LOG2";
  #-n[0] 0,1 -oneminus[0] -n[0] 0,255
  verbose($cmd);
  print("--------> lineart from color input\n");
  system $cmd;
  #
  #make lineart
  $cmd="$GMIC $HINT $MINIMA -fx_colorize_lineart_smartcoloring 1,95,0,0,0,1,24,200,0,0,1,0,0,0,0,0,1,0,20,64,7.5,0.5,0 -o[2] $LINEART1 $LOG2";
  #-n[0] 0,1 -oneminus[0] -n[0] 0,255
  verbose($cmd);
  print("--------> lineart from hint\n");
  system $cmd;
  if ($DOCOMPO)
  {
  if ($DREAMSMOOTH)
    {
    $GMICSMOOTH="-fx_dreamsmooth 10,0,1,0.8,0,0.8,0,24,0";
    print("--------> dreamsmooth\n");
    } else {$GMICSMOOTH="";}
  if ($DILATE)
    {
    $GMICDILATE="-erode_circ[1] $DILATE";
    print("--------> dilate edges [dilate:$DILATE]\n");
    } else {$GMICDILATE="";}
  $cmd="$GMIC $LINEART -fx_sharp_abstract[0] 1,10,0.5,0,0 $POTRACES -to_colormode[1] 3 -n[1] 0,1 -oneminus[1] -n[1] 0,255 $GMICDILATE $GMICSMOOTH -blend $BLENDMODE,$BLENDOPACITY -o $COMPO $LOG2";
  verbose($cmd);
  print("--------> compo [erode:$DILATE dreamsmooth:$DREAMSMOOTH blendmode:$BLENDMODE blendopacity:$BLENDOPACITY]\n");
  system $cmd;
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
