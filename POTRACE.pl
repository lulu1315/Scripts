#!/usr/bin/perl

use Cwd;
use Env;
use Term::ANSIColor qw(:constants);
use Image::Magick;
#http://www.imagemagick.org/script/command-line-options.php
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
$SHOT="";
$INDIR="$CWD/originales";
$IN="ima";
$IN_USE_SHOT=0;
$OUTDIR="$CWD/$scriptname";
$OUT="$scriptname";
$OUT_USE_SHOT=0;
$ZEROPAD=1;
$FORCE=0;
$EXT="png";
$EXTIN="png";
$EXTOUT="png";
#preprocess
$SIZE=0;
$DOLOCALCONTRAST=0;
$ROLLING=0;
$BRIGHTNESS=0;
$CONTRAST=0;
$GAMMA=0;
$SATURATION=0;
#
$BLACKLEVEL=.1;
$OUTSMOOTH=0;
#
$DXF=0;
$VERBOSE=0;
$CLEAN=1;
$GPU=0;
$CSV=0;
$LOG1=">/var/tmp/$scriptname.log";
$LOG2="2>/var/tmp/$scriptname.log";

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
print AUTOCONF confstr(SHOT);
print AUTOCONF confstr(INDIR);
print AUTOCONF confstr(IN);
print AUTOCONF confstr(IN_USE_SHOT);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(OUT);
print AUTOCONF confstr(OUT_USE_SHOT);
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(EXTIN);
print AUTOCONF confstr(EXTOUT);
print AUTOCONF "#preprocess\n";
print AUTOCONF confstr(SIZE);
print AUTOCONF confstr(DOLOCALCONTRAST);
print AUTOCONF confstr(ROLLING);
print AUTOCONF confstr(BRIGHTNESS);
print AUTOCONF confstr(CONTRAST);
print AUTOCONF confstr(GAMMA);
print AUTOCONF confstr(SATURATION);
print AUTOCONF "#potrace\n";
print AUTOCONF confstr(BLACKLEVEL);
print AUTOCONF confstr(OUTSMOOTH);
print AUTOCONF "#misc\n";
print AUTOCONF confstr(DXF);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF confstr(CLEAN);
print AUTOCONF confstr(GPU);
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
    print "writing $scriptname\_auto.conf : mv $scriptname\_auto.conf $scriptname.conf\n";
    autoconf();
    exit;
    }
  if (@ARGV[$arg] eq "-conf") 
    {
    $CONF=@ARGV[$arg+1];
    print "using conf file $CONF\n";
    require $CONF;
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
    $LOG1="";
    $LOG2="";
    print "verbose on\n";
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
if ($userName eq "lulu" || $userName eq "dev" || $userName eq "render")	#
  {
  $GMIC="/usr/bin/gmic";
  $POTRACE="/usr/bin/potrace";
  }
  
if ($VERBOSE) {$LOG1="";$LOG2="";}

sub csv {
for ($i = $FSTART ;$i <= $FEND;$i++)
{
$ii=sprintf("%04d",$i);
if ($IN_USE_SHOT)
    {
    $IIN="$INDIR/$SHOT/$IN.$ii.$EXTIN";
    }
else
    {
    $IIN="$INDIR/$IN.$ii.$EXTIN";
    }
    
if ($OUT_USE_SHOT)
    {
    $OOUTDIR="$OUTDIR/$SHOT";
    $OOUT="$OOUTDIR/$OUT.$ii.$EXTOUT";
    $OOUTDXF="$OOUTDIR/$OUT.$ii.dxf";
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    }
else
    {
    $OOUTDIR="$OUTDIR";
    $OOUT="$OOUTDIR/$OUT.$ii.$EXTOUT";
    $OOUTDXF="$OOUTDIR/$OUT.$ii.dxf";
    }

if (-e $OOUT && !$FORCE)
   {print BOLD RED "frame $OOUT exists ... skipping\n";print RESET;}
else {
  #touch file
  $touchcmd="touch $OOUT";
  verbose($touchcmd);
  system $touchcmd;
  #start timer
  #-----------------------------#
  ($s1,$m1,$h1)=localtime(time);
  #-----------------------------#
  #workdir
  $WORKDIR="$OOUTDIR/w$ii";
  if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
  #preprocess
  $I=1;
  if ($DOLOCALCONTRAST) 
        {$GMIC1="-fx_LCE[0] 80,0.5,1,1,0,0";} 
    else {$GMIC1="";}
    if ($ROLLING) 
        {$GMIC2="-fx_sharp_abstract $ROLLING,10,0.5,0,0";} 
    else {$GMIC2="";}
    if ($BRIGHTNESS || $CONTRAST || $GAMMA || $SATURATION) 
        {$GMIC3="-fx_adjust_colors $BRIGHTNESS,$CONTRAST,$GAMMA,0,$SATURATION";} 
    else {$GMIC3="";}
    if ($SIZE) 
        {$GMIC4="-resize2dx $SIZE,5";} 
    else {$GMIC4="";}
    if ($EXTIN eq "exr") 
        {$GMIC5="-n 0,255";} 
    else {$GMIC5="";}
  $cmd="$GMIC -i $IIN $GMIC5 $GMIC4 $GMIC1 $GMIC2 $GMIC3 -o $WORKDIR/$I.pgm $LOG2";
  verbose($cmd);
  print("--------> preprocess input [size:$SIZE lce:$DOLOCALCONTRAST rolling:$ROLLING bcgs:$BRIGHTNESS/$CONTRAST/$GAMMA/$SATURATION]\n");
  system $cmd;
  #potrace
  $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
  $cmd="$POTRACE $PIN -o $POUT -g -k $BLACKLEVEL";
  verbose($cmd);
  print("--------> potrace [blacklevel:$BLACKLEVEL]\n");
  system $cmd;
  #dxf
  if ($DXF)
    {
    $cmd="$POTRACE $PIN -o $OOUTDXF -b dxf -k $BLACKLEVEL";
    verbose($cmd);
    print("--------> potrace dxf [blacklevel:$BLACKLEVEL]\n");
    system $cmd;
    }
  #bug potrace
  $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
  $cmd="convert $PIN $POUT";
  verbose($cmd);
  print("--------> potrace bug\n");
  system $cmd;
  #
  if ($OUTSMOOTH) 
    {$GMIC1="-fx_dreamsmooth 10,0,1,0.8,0,0.8,0,24,0";} else {$GMIC1="";}
  $cmd="$GMIC $POUT -to_colormode 3 $GMIC1 -o $OOUT $LOG2";
  verbose($cmd);
  print("--------> output [smooth:$OUTSMOOTH]\n");
  system $cmd;
  #-----------------------------#
  ($s2,$m2,$h2)=localtime(time);
  ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
  #-----------------------------#
  #afanasy parsing format
  print BOLD YELLOW "Writing $OOUT took $hlat:$mlat:$slat\n";print RESET;
  if ($CLEAN)
    {
    $cleancmd="rm -r $WORKDIR";
    verbose($cleancmd);
    system $cleancmd;
    }
  }
}
}

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
  
#gestion des keyframes
sub keyframe {
    @keyvals = split(/,/,$_[0]);
    #print "keyvals = @keyvals\n";
    $key1=$keyvals[0];
    $key2=$keyvals[1];
    return $key1+$keycount*(($key2-$key1)/($KEYFRAME-1));
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
