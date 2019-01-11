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
$IN_USE_SHOT=0;
$OUT_USE_SHOT=0;
$SHOT="";
$INDIR="$CWD/originales";
$IN="ima";
$OUTDIR="$CWD/$scriptname";
$OUT="ima";
$ZEROPAD=1;
$FORCE=0;
$EXT="png";
$VERBOSE=0;
$NETWORKSIZE=224;
$METHOD=0;
#preprocess
$SIZE=0;
$DOLOCALCONTRAST=0;
$ROLLING=2;
$BRIGHTNESS=0;
$CONTRAST=0;
$GAMMA=0;
$SATURATION=0;
#
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
print AUTOCONF confstr(IN_USE_SHOT);
print AUTOCONF confstr(OUT_USE_SHOT);
print AUTOCONF confstr(SHOT);
print AUTOCONF confstr(INDIR);
print AUTOCONF confstr(IN);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(OUT);
print AUTOCONF confstr(NETWORKSIZE);
print AUTOCONF confstr(METHOD);
print AUTOCONF "#0 : all\n";
print AUTOCONF "#1 : lettherebecolor\n";
print AUTOCONF "#2 : autocolor\n";
print AUTOCONF "#3 : zhangcolor1\n";
print AUTOCONF "#4 : zhangcolor2\n";
print AUTOCONF "#preprocess\n";
print AUTOCONF confstr(SIZE);
print AUTOCONF confstr(DOLOCALCONTRAST);
print AUTOCONF confstr(ROLLING);
print AUTOCONF confstr(BRIGHTNESS);
print AUTOCONF confstr(CONTRAST);
print AUTOCONF confstr(GAMMA);
print AUTOCONF confstr(SATURATION);
print AUTOCONF "#misc\n";
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF confstr(CLEAN);
print AUTOCONF confstr(GPU);
print AUTOCONF confstr(CSV);
print AUTOCONF "1\n";
}

if ($#ARGV == -1) {
  print "usage: $scriptname \n";
      print "-f startframe endframe\n";
      print "-idir dirin\n";
      print "-i imagein\n";
      print "-odir dirout\n";
      print "-o imageout\n";
      print "-e image ext (png)\n";
      print "-zeropad4\n";
      print "-force\n";
      print "-networksize [224]\n";
      print "-gpu [0]\n";
      print "-csv csv_file.csv\n";
      exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-autoconf")
    {
    print "mv $scriptname\_auto.conf $scriptname.conf\n";
    autoconf();
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
    $LOG="";
    print "force output ...\n";
    }
  if (@ARGV[$arg] eq "-networksize") 
    {
    $NETWORKSIZE=@ARGV[$arg+1];
    print "networksize : $NETWORKSIZE\n";
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
  
if ($userName eq "dev18")	#
  {
  $GMIC="/usr/bin/gmic";
  $TH="/shared/foss-18/torch/install/bin/th";
  $LETTHERE_LUA="/shared/foss/siggraph2016_colorization/colorize.lua";
  $LETTHERE_MODEL="/shared/foss/siggraph2016_colorization/colornet.t7";
  $CPU="";
  $AUTOCOLORIZE="/usr/local/bin/autocolorize";
  $ZHANGCOLORIZE1="python3 /shared/foss-18/colorization/color.py";
  $ZHANGPROTO1="/shared/foss-18/colorization/models/colorization_deploy_v1.prototxt";
  $ZHANGMODEL1="/shared/foss-18/colorization/models/colorization_release_v1.caffemodel";
  $ZHANGCOLORIZE2="python3 /shared/foss-18/colorization/color_v2.py";
  $ZHANGPROTO2="/shared/foss-18/colorization/models/colorization_deploy_v2.prototxt";
  $ZHANGMODEL2="/shared/foss-18/colorization/models/colorization_release_v2.caffemodel";
  $ZHANGCOLORIZE3="python3 /shared/foss-18/colorization/color_v2.py";
  $ZHANGPROTO3="/shared/foss-18/colorization/models/colorization_deploy_v2.prototxt";
  $ZHANGMODEL3="/shared/foss-18/colorization/models/colorization_release_v2_norebal.caffemodel";
  $ENV{PYTHONPATH} = "/shared/foss-18/caffe/python:$ENV{'PYTHONPATH'}";
  verbose("PYTHONPATH : $ENV{'PYTHONPATH'}");
  }
if ($VERBOSE) {$LOG1="";$LOG2="";}

sub csv {

#auto frames
if ($FSTART eq "auto" || $FEND eq "auto")
    {
    if ($IN_USE_SHOT) {$AUTODIR="$INDIR/$SHOT";} else {$AUTODIR="$INDIR";}
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
if ($IN_USE_SHOT)
    {
    $IIN="$INDIR/$SHOT/$IN.$ii.$EXT";
    }
else
    {
    $IIN="$INDIR/$IN.$ii.$EXT";
    }
    
if ($OUT_USE_SHOT)
    {
    $OOUTDIR="$OUTDIR/$SHOT";
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    }
else
    {
    $OOUTDIR="$OUTDIR";
    }
    
if ($METHOD)
    {
    $OOUT="$OOUTDIR/$OUT$PARAMS\_m$METHOD.$ii.$EXT";
    }
else
    {
    $OOUT="$OOUTDIR/$OUT$PARAMS\_m1.$ii.$EXT";
    }
    
if (-e $OOUT && !$FORCE)
   {print BOLD RED "\nframe $OOUT exists ... skipping\n";print RESET;}
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
  $cmd="$GMIC -i $IIN $GMIC4 $GMIC1 $GMIC2 $GMIC3 -o $WORKDIR/$I.png $LOG2";
  verbose($cmd);
  print("--------> preprocess input [size:$SIZE lce:$DOLOCALCONTRAST rolling:$ROLLING bcgs:$BRIGHTNESS/$CONTRAST/$GAMMA/$SATURATION]\n");
  system $cmd;
  $IIN="$WORKDIR/$I.png";
  
  if ($METHOD == 1 || $METHOD == 0)
    {
    #-----------------------------#
    ($s11,$m11,$h11)=localtime(time);
    #-----------------------------#
    $OOUT="$OOUTDIR/$OUT$PARAMS\_m1.$ii.$EXT";
    $NETWORK="$WORKDIR/network.$ii.$EXT";
    $COLORIMA="$WORKDIR/color.$ii.$EXT";
    $resizecmd="$GMIC -i $IIN -resize2dx $NETWORKSIZE,5 -o $NETWORK $LOG2";
    system $resizecmd;
    $colorcmd="$TH $LETTHERE_LUA $NETWORK $COLORIMA $LETTHERE_MODEL";
    verbose($colorcmd);
    system $colorcmd;
    $combinecmd="$GMIC -i $IIN $COLORIMA \\
    -rgb2yuv8[1] -resize[1] [0],5 \\
    -channels[0] 0 -channels[1] 1,2 \\
    -split[1] c -append c -yuv82rgb -o $OOUT $LOG2";
    system $combinecmd;
    #-----------------------------#
    ($s21,$m21,$h21)=localtime(time);
    ($slat,$mlat,$hlat) = lapse($s11,$m11,$h11,$s21,$m21,$h21);
    print("--------> method 1 : lettherebecolor");
    print BOLD GREEN " took $hlat:$mlat:$slat\n";print RESET;
    #-----------------------------#
    }
  if ($METHOD == 2 || $METHOD == 0)
    {   
    #-----------------------------#
    ($s11,$m11,$h11)=localtime(time);
    #-----------------------------#
    $OOUT="$OOUTDIR/$OUT$PARAMS\_m2.$ii.$EXT";
    $cmd="$AUTOCOLORIZE $CPU $IIN -o $OOUT -s $NETWORKSIZE $LOG2";
    verbose($cmd);
    system $cmd;
    #-----------------------------#
    ($s21,$m21,$h21)=localtime(time);
    ($slat,$mlat,$hlat) = lapse($s11,$m11,$h11,$s21,$m21,$h21);
    print("--------> method 2 : autocolorize");
    print BOLD GREEN " took $hlat:$mlat:$slat\n";print RESET;
    #-----------------------------#
    }
  if ($METHOD == 3 || $METHOD == 0)
    { 
    #-----------------------------#
    ($s11,$m11,$h11)=localtime(time);
    #-----------------------------#
    $OOUT="$OOUTDIR/$OUT$PARAMS\_m3.$ii.$EXT";
    $cmd="$ZHANGCOLORIZE1 $IIN $OOUT $ZHANGPROTO1 $ZHANGMODEL1 $LOG2";
    verbose($cmd);
    system $cmd;
    #-----------------------------#
    ($s21,$m21,$h21)=localtime(time);
    ($slat,$mlat,$hlat) = lapse($s11,$m11,$h11,$s21,$m21,$h21);
    print("--------> method 3 : zhangcolor v1");
    print BOLD GREEN " took $hlat:$mlat:$slat\n";print RESET;
    #-----------------------------#
    } 
  if ($METHOD == 4 || $METHOD == 0)
    {   
    #-----------------------------#
    ($s11,$m11,$h11)=localtime(time);
    #-----------------------------#
    $OOUT="$OOUTDIR/$OUT$PARAMS\_m4.$ii.$EXT";
    $cmd="$ZHANGCOLORIZE2 $IIN $OOUT $ZHANGPROTO2 $ZHANGMODEL2 $LOG2";
    verbose($cmd);
    system $cmd;
    #-----------------------------#
    ($s21,$m21,$h21)=localtime(time);
    ($slat,$mlat,$hlat) = lapse($s11,$m11,$h11,$s21,$m21,$h21);
    print("--------> method 4 : zhangcolor v2");
    print BOLD GREEN " took $hlat:$mlat:$slat\n";print RESET;
    #-----------------------------#
    } 
  if ($METHOD == 5) #pas grand interet
    {   
    #-----------------------------#
    ($s11,$m11,$h11)=localtime(time);
    #-----------------------------#
    $OOUT="$OOUTDIR/$OUT$PARAMS\_m5.$ii.$EXT";
    $cmd="$ZHANGCOLORIZE3 $IIN $OOUT $ZHANGPROTO3 $ZHANGMODEL3 $LOG2";
    verbose($cmd);
    system $cmd;
    #-----------------------------#
    ($s21,$m21,$h21)=localtime(time);
    ($slat,$mlat,$hlat) = lapse($s11,$m11,$h11,$s21,$m21,$h21);
    print("--------> method 5 : zhangcolor v3");
    print BOLD GREEN " took $hlat:$mlat:$slat\n";print RESET;
    #-----------------------------#
    } 
  if ($METHOD == 0)
    {
    $M1="$OOUTDIR/$OUT$PARAMS\_m1.$ii.$EXT";
    $M2="$OOUTDIR/$OUT$PARAMS\_m2.$ii.$EXT";
    $M3="$OOUTDIR/$OUT$PARAMS\_m3.$ii.$EXT";
    $M4="$OOUTDIR/$OUT$PARAMS\_m4.$ii.$EXT";
    $cmd="$GMIC $M1 $M2 $M3 $M4 -text_outline[0] \"1\" -text_outline[1] \"2\" -text_outline[2] \"3\" -text_outline[3] \"4\" -montage X -o $OOUTDIR/$OUT$PARAMS\_montage.$ii.$EXT $LOG2";
    #$cmd="$GMIC $M1 $M2 $M3 $M4 -montage X -o $OOUTDIR/$OUT$PARAMS\_montage.$ii.$EXT $LOG2";
    verbose($cmd);
    print("--------> montage\n");
    system $cmd;
    }
  #-----------------------------#
  ($s2,$m2,$h2)=localtime(time);
  ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
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
