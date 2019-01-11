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
$FSTEP=1;
$SHOT="";
$INDIR="$CWD/originales";
$IN="ima";
$IN_USE_SHOT=0;
$OUTDIR="$CWD/edges";
$OUT="edges";
$OUT_USE_SHOT=0;
$ZEROPAD=1;
$FORCE=0;
$EXT="png";
$EXTIN="\$EXT";
$EXTOUT="\$EXT";
$VERBOSE=0;
#preprocess
$DOLOCALCONTRAST=0;
$EQUALIZE=0;
$ROLLING=2;
$BRIGHTNESS=0;
$CONTRAST=0;
$GAMMA=0;
$SATURATION=0;
#edges params
$SIZE=0;
$METHOD=9;
#0 : all
#1 : imagemagick canny
#2 : opencv canny
#3 : gmic = fx_edges
#4 : hed
#5 : canny deriche (pink)
#6 : gradient norm
#7 : watershed
#8 : lulu method
#9 : lulu method with potrace
#10 : ColorED
#11 : GrayScaleEDPF
$SIGMA=1;
$AUTOMODE=0;
$AUTOSIGMA=.33;
$MAGICKFACTOR=40;
$GMICFACTOR=15;
$MEDIAN=20;
$ECARTYPE=8;
$ALPHA=.5;
$CONNEX=8;
$NITERS=8;
$EDGEGAMMA=1.1;
$EDGESMOOTH=1;
$EDGELOCALCONTRAST=1;
$KEEPINPUT=0;
#post process
$INVFINAL=0;
#potrace
$BLACKLEVEL=.5;
$CLEAN=1;
$GPU=0;
$CSV=0;
$LOG1=">/var/tmp/$scriptname.log";
$LOG2="2>/var/tmp/$scriptname.log";
#JSON
$CAPACITY=250;
$SKIP="-force";
$FPT=5;

$help="If {+upper-percent} is increased but {+lower-percent} remains the same, lesser edge components will be detected, but their lengths will be the same.\n If {+lower-percent} is increased but {+upper-percent} is the same, the same number of edge components will be detected but their lengths will be shorter";

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
print AUTOCONF confstr(FSTEP);
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
print AUTOCONF confstr(VERBOSE);
print AUTOCONF "#preprocess\n";
print AUTOCONF confstr(DOLOCALCONTRAST);
print AUTOCONF confstr(EQUALIZE);
print AUTOCONF confstr(ROLLING);
print AUTOCONF confstr(BRIGHTNESS);
print AUTOCONF confstr(CONTRAST);
print AUTOCONF confstr(GAMMA);
print AUTOCONF confstr(SATURATION);
print AUTOCONF "#edges params\n";
print AUTOCONF confstr(SIZE);
print AUTOCONF confstr(METHOD);
print AUTOCONF "#0 : all\n";
print AUTOCONF "#1 : imagemagick canny\n";
print AUTOCONF "#2 : opencv canny\n";
print AUTOCONF "#3 : gmic edges\n";
print AUTOCONF "#4 : hed\n";
print AUTOCONF "#5 : pink canny deriche\n";
print AUTOCONF "#6 : gmic gradient norm\n";
print AUTOCONF "#7 : pink watershed\n";
print AUTOCONF "#8 : lulu method\n";
print AUTOCONF "#9 : lulu method with potrace\n";
print AUTOCONF "#10 : ColorED\n";
print AUTOCONF "#11 : GrayScaleEDPF (Parameter Free)\n";
print AUTOCONF confstr(SIGMA);
print AUTOCONF confstr(AUTOMODE);
print AUTOCONF confstr(AUTOSIGMA);
print AUTOCONF confstr(MAGICKFACTOR);
print AUTOCONF confstr(GMICFACTOR);
print AUTOCONF confstr(MEDIAN);
print AUTOCONF confstr(ECARTYPE);
print AUTOCONF confstr(ALPHA);
print AUTOCONF confstr(CONNEX);
print AUTOCONF confstr(NITERS);
print AUTOCONF confstr(EDGEGAMMA);
print AUTOCONF confstr(EDGESMOOTH);
print AUTOCONF confstr(EDGELOCALCONTRAST);
print AUTOCONF confstr(KEEPINPUT);
print AUTOCONF "#misc\n";
print AUTOCONF confstr(INVFINAL);
print AUTOCONF confstr(BLACKLEVEL);
print AUTOCONF confstr(CLEAN);
print AUTOCONF confstr(GPU);
print AUTOCONF "#json - submit to afanasy\n";
print AUTOCONF confstr(CAPACITY);
print AUTOCONF confstr(SKIP);
print AUTOCONF confstr(FPT);
print AUTOCONF "1\n";
}

if ($#ARGV == -1) {
	print "usage: $scriptname.pl \n";
	print "-autoconf\n";
	print "-conf file.conf\n";
	print "-f startframe endframe\n";
    print "-fstep [1]\n";
	print "-idir dirin\n";
	print "-i imagein\n";
	print "-odir dirout\n";
	print "-o imageout\n";
	print "-shot shotname\n";
	print "-zeropad4 [1]\n";
	print "-force [0]\n";
	print "-verbose\n";
	print "-gpu [0]\n";
    print "-csv csv_file.csv\n";
	print "-json [submit to afanasy]\n";	
	print "\nhelp :\n $help\n";
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
  if (@ARGV[$arg] eq "-fstep") 
    {
    $FSTEP=@ARGV[$arg+1];
    print "fstep : $FSTEP\n";
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
 if (@ARGV[$arg] eq "-shot") 
    {
    $SHOT=@ARGV[$arg+1];
    print "shotname : $SHOT\n";
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
  if (@ARGV[$arg] eq "-json") 
    {
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
                json();
                }
            }
        }
        else
        {
        json();
        }
    exit;
    }
  if (@ARGV[$arg] eq "-xml") 
    {
    open (XML,">","submit.xml");
    print XML "<rrJob_submitFile syntax_version=\"6.0\">\n";
    print XML "<DeleteXML>1</DeleteXML>\n";
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
            xml();
            }
        }
    }
    else
    {
    xml();
    }
    print XML "</rrJob_submitFile>\n";
    $cmd="/shared/apps/royal-render/lx__rrSubmitter.sh submit.xml";
    print $cmd;
    system $cmd;
    exit;
    }
  }
  
$userName =  $ENV{'USER'}; 
if ($userName eq "dev" || $userName eq "render")	#
  {
  $GMIC="/shared/foss/gmic/src/gmic";
  $AUTOCANNY="python /shared/Scripts/python/auto_canny.py";
  $GETMEDIAN="python /shared/Scripts/python/median.py";
  $HED="python /shared/foss/hed/examples/hed/make_hed.py";
  $PINKBIN="/shared/foss/Pink/linux/bin";
  $POTRACE="/usr/bin/potrace";
  $COLORED="/shared/foss/ED/ColorED/ColorEDTest";
  $EDPF="/shared/foss/ED/ED/EDTest";
  $ENV{PYTHONPATH} = "/shared/foss/hed/python:$ENV{'PYTHONPATH'}";
  $ENV{PATH} = "/shared/foss/Pink/linux/bin:$ENV{'PATH'}";
  }
  
if ($userName eq "lulu")	#
  {
  $GMIC="/shared/foss/gmic/src/gmic";
  $AUTOCANNY="python /mnt/OwnCloud/Scripts/python/auto_canny.py";
  $GETMEDIAN="python /mnt/OwnCloud/Scripts/python/median.py";
  $HED="python /shared/foss/hed/examples/hed/make_hed.py";
  $PINKBIN="/shared/foss/Pink/linux/bin";
  $ENV{PYTHONPATH} = "/shared/foss/hed/python:$ENV{'PYTHONPATH'}";
  }
  
$RADIUS=$SIGMA*3;
if ($INVFINAL) 
    {$GMICINV = "-n 0,1 -oneminus -n 0,255";} else {$GMICINV = "";}

if ($VERBOSE) {$LOG1="";$LOG2="";}

for ($i = $FSTART ;$i <= $FEND;$i=$i+$FSTEP)
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
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    }
else
    {
    $OOUTDIR="$OUTDIR";
    }
#preprocess
if ($METHOD)
    {$OOUT="$OOUTDIR/$OUT\_m$METHOD.$ii.$EXT";}
else
    {$OOUT="$OOUTDIR/$OUT\_m1.$ii.$EXT";}
    
$WORKDIR="$OOUTDIR/w$ii";

if (-e $OOUT && !$FORCE)
{print BOLD RED "frame $OOUT exists ... skipping\n";print RESET;}
else
  {
  #touch file
  $touchcmd="touch $OOUT";
  verbose($touchcmd);
  system $touchcmd;
  if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
  verbose("processing frame $ii");
  #-----------------------------#
  ($s1,$m1,$h1)=localtime(time);
  #-----------------------------#
  #preprocess
  $I=1;
  if ($DOLOCALCONTRAST) 
        {$GMIC1="-fx_LCE[0] 80,0.5,1,1,0,0";} 
    else {$GMIC1="";}
  if ($ROLLING) 
        {$GMIC2="-fx_sharp_abstract $ROLLING,10,0.5,0,0";} 
  if ($EQUALIZE) 
        {$GMIC5="-equalize";} 
    else {$GMIC5="";}
  if ($BRIGHTNESS || $CONTRAST || $GAMMA || $SATURATION) 
        {$GMIC3="-fx_adjust_colors $BRIGHTNESS,$CONTRAST,$GAMMA,0,$SATURATION";} 
    else {$GMIC3="";}
    if ($SIZE) 
        {$GMIC4="-resize2dx $SIZE,5";} 
  $cmd="$GMIC -i $IIN $GMIC5 $GMIC4 $GMIC1 $GMIC2 $GMIC3 -o $WORKDIR/$I.png $LOG2";
  verbose($cmd);
  print("--------> preprocess input [size:$SIZE equalize:$EQUALIZE lce:$DOLOCALCONTRAST rolling:$ROLLING bcgs:$BRIGHTNESS/$CONTRAST/$GAMMA/$SATURATION]\n");
  system $cmd;
  $IIN="$WORKDIR/$I.png";
  $OOUT="$OOUTDIR/$OUT\_input.$ii.$EXT";
  if ($KEEPINPUT)
    {
    $cmd="cp $IIN $OOUT";
    verbose($cmd);
    print("--------> keeping input $OOUT\n");
    system $cmd;
    }
  #
  if ($AUTOMODE)
    {
    $mediancmd = "$GETMEDIAN -i $IIN";
    verbose($mediancmd);
    $medianvalue=`$mediancmd`;
    $MEDIAN=$medianvalue*1.0;
    $LPC = int(max(0, (1.0 - $AUTOSIGMA) * $MEDIAN));
    $HPC = int(min(255, (1.0 + $AUTOSIGMA) * $MEDIAN));
    verbose("median : $MEDIAN");
    $ECARTYPE=int(($HPC-$LPC)/2);
    print("--------> getting median [$MEDIAN]\n");
    }
  else
    {
    $LPC=max(0,$MEDIAN-$ECARTYPE);
    $HPC=min(255,$MEDIAN+$ECARTYPE);
    }
  if ($METHOD == 1 || $METHOD == 0)
    {
    $OOUT="$OOUTDIR/$OUT\_m1.$ii.$EXT";
    $LPC1=int($LPC*$MAGICKFACTOR/255);
    $HPC1=int($HPC*$MAGICKFACTOR/255);
    $canny=$RADIUS."x".$SIGMA."+".$LPC1."%+".$HPC1."%";
    #verbose("magick m/e : $MEDIAN\/$ECARTYPE u/l : $LPC\/$HPC");
    $cmd="convert $IIN -canny $canny $OOUT";
    verbose($cmd);
    print("--------> imagemagick canny [m/e : $MEDIAN\/$ECARTYPE u/l : $LPC1\/$HPC1]\n");
    system $cmd;
    if ($INVFINAL)
        {
        $cmd="$GMIC $OOUT $GMICINV -o $OOUT $LOG2";
        verbose($cmd);
        print("--------> inverting final\n");
        system $cmd;
        }
    }
  if ($METHOD == 2 || $METHOD == 0)
    {
    $OOUT="$OOUTDIR/$OUT\_m2.$ii.$EXT";
    #verbose("opencv m/e : $MEDIAN\/$ECARTYPE u/l : $LPC\/$HPC");
    $cmd="$AUTOCANNY -i $IIN -o $OOUT -l $LPC -u $HPC -s $SIGMA";
    verbose($cmd);
    print("--------> opencv canny [m/e : $MEDIAN\/$ECARTYPE u/l : $LPC\/$HPC]\n");
    system $cmd;
    if ($INVFINAL)
        {
        $cmd="$GMIC $OOUT $GMICINV -o $OOUT $LOG2";
        verbose($cmd);
        print("--------> inverting final\n");
        system $cmd;
        }
    }
  if ($METHOD == 3 || $METHOD == 0)
    {
    $OOUT="$OOUTDIR/$OUT\_m3.$ii.$EXT";
    verbose("gmic edge treshold : $GMICFACTOR");
    #$cmd="$GMIC -i $IIN edges $GMICFACTOR -oneminus -n 0,255 -o $OOUT $LOG2";
    $cmd="$GMIC -i $IIN -gradient_norm -b 0.5 \\>= $GMICFACTOR% -distance 0,2 -equalize -negate -c 30%,70%  -n 0,255 -o $OOUT $LOG2";
    verbose($cmd);
    print("--------> gmic edge [treshold:$GMICFACTOR]\n");
    system $cmd;
    if ($INVFINAL)
        {
        $cmd="$GMIC $OOUT $GMICINV -o $OOUT $LOG2";
        verbose($cmd);
        print("--------> inverting final\n");
        system $cmd;
        }
    }
  if ($METHOD == 4 || $METHOD == 0)
    {
    $OOUT="$OOUTDIR/$OUT\_m4.$ii.$EXT";
    $cmd="$HED --image_in $IIN --image_out=$IIN --gpu_id $GPU 2>/var/tmp/$scriptname.log";
    #$cmd="$HED --image_in $IIN --image_out=$IIN --gpu_id $GPU";
    verbose($cmd);
    system $cmd;
    $cmd="$GMIC -i $WORKDIR/$I.tiff -mul 255 -to_colormode 3 -o $OOUT $LOG2";
    verbose($cmd);
    print("--------> HED\n");
    system $cmd;
    if ($INVFINAL)
        {
        $cmd="$GMIC $OOUT $GMICINV -o $OOUT $LOG2";
        verbose($cmd);
        print("--------> inverting final\n");
        system $cmd;
        }
    }
  if ($METHOD == 5 || $METHOD == 0)
    {
    $OOUT="$OOUTDIR/$OUT\_m5.$ii.$EXT";
    $I=1;
    $cmd="$GMIC $IIN -to_colormode 1 -o $WORKDIR/$I.pgm $LOG2";
    verbose($cmd);
    system $cmd;
    $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$PINKBIN/gradientcd $PIN $ALPHA $POUT";
    verbose($cmd);
    print("--------> Canny Deriche [alpha:$ALPHA]\n");
    system $cmd;
    #--> formatting gradient
    $cmd="$GMIC -i $POUT -to_colormode 3 -o $OOUT $LOG2";
    verbose($cmd);
    system $cmd;
    if ($INVFINAL)
        {
        $cmd="$GMIC $OOUT $GMICINV -o $OOUT $LOG2";
        verbose($cmd);
        print("--------> inverting final\n");
        system $cmd;
        }
    }
  if ($METHOD == 6 || $METHOD == 0)
    {
    $OOUT="$OOUTDIR/$OUT\_m6.$ii.$EXT";
    $cmd="$GMIC -i $IIN -gradient_norm -o $OOUT $LOG2";
    verbose($cmd);
    print("--------> gmic gradient_norm\n");
    system $cmd;
    if ($INVFINAL)
        {
        $cmd="$GMIC $OOUT $GMICINV -o $OOUT $LOG2";
        verbose($cmd);
        print("--------> inverting final\n");
        system $cmd;
        }
    }
  if ($METHOD == 7 || $METHOD == 0)
    {
    $OOUT="$OOUTDIR/$OUT\_m7.$ii.$EXT";
    $I=1;
    $cmd="$GMIC $IIN -to_colormode 1 -o $WORKDIR/$I.pgm $LOG2";
    verbose($cmd);
    system $cmd;
    $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$PINKBIN/wshedtopo $PIN $CONNEX $POUT";
    verbose($cmd);
    print("--------> Watershed [connex:$CONNEX]\n");
    system $cmd;
    #minima
    $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$PINKBIN/minima $PIN $CONNEX $POUT";
    verbose($cmd);
    print("--------> minima  [connex:$CONNEX]\n");
    system $cmd;
    #--> formatting gradient
    $cmd="$GMIC -i $POUT -n 0,1 -oneminus -n 0,255 -to_colormode 3 -o $OOUT $LOG2";
    verbose($cmd);
    system $cmd;
    if ($INVFINAL)
        {
        $cmd="$GMIC $OOUT $GMICINV -o $OOUT $LOG2";
        verbose($cmd);
        print("--------> inverting final\n");
        system $cmd;
        }
    }
  if ($METHOD == 8 || $METHOD == 0)
    {
    $OOUT="$OOUTDIR/$OUT\_m8.$ii.$EXT";
    $I=1;
    $cmd="$GMIC $IIN -to_colormode 1 -o $WORKDIR/$I.pgm $LOG2";
    verbose($cmd);
    system $cmd;
    #
    $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$PINKBIN/gradientcd $PIN $ALPHA $POUT";
    verbose($cmd);
    print("--------> Canny Deriche [alpha:$ALPHA]\n");
    system $cmd;
    #
    $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$PINKBIN/hthin $PIN null $CONNEX $NITERS $POUT";
    verbose($cmd);
    print("--------> hthin [connex:$CONNEX] niters:$NITERS]\n");
    system $cmd;
    #--> formatting gradient
    if ($EDGELOCALCONTRAST) 
        {$GMIC1="-fx_LCE[0] 80,0.5,1,1,0,0";} else {$GMIC1="";}
    if ($EDGESMOOTH) 
        {$GMIC2="-fx_dreamsmooth 10,0,1,0.8,0,0.8,0,24,0";} else {$GMIC2="";}
    $cmd="$GMIC -i $POUT -b 0.5 -n 0,1 -apply_gamma $EDGEGAMMA -n 0,255 $GMIC2 $GMIC1 -o $OOUT $LOG2";
    verbose($cmd);
    print("--------> method 8 [edgegamma:$EDGEGAMMA] lce:$EDGELOCALCONTRAST smooth:$EDGESMOOTH]\n");
    system $cmd;
    if ($INVFINAL)
        {
        $cmd="$GMIC $OOUT $GMICINV -o $OOUT $LOG2";
        verbose($cmd);
        print("--------> inverting final\n");
        system $cmd;
        }
    }
  if ($METHOD == 9 || $METHOD == 0)
    {
    $OOUT="$OOUTDIR/$OUT\_m9.$ii.$EXT";
    $I=1;
    $cmd="$GMIC $IIN -to_colormode 1 -o $WORKDIR/$I.pgm $LOG2";
    verbose($cmd);
    system $cmd;
    #
    $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$PINKBIN/gradientcd $PIN $ALPHA $POUT";
    verbose($cmd);
    print("--------> Canny Deriche [alpha:$ALPHA]\n");
    system $cmd;
    #
    $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$PINKBIN/hthin $PIN null $CONNEX $NITERS $POUT";
    verbose($cmd);
    print("--------> hthin [connex:$CONNEX] niters:$NITERS]\n");
    system $cmd;
    #--> formatting gradient
    $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    if ($EDGELOCALCONTRAST) 
        {$GMIC1="-fx_LCE[0] 80,0.5,1,1,0,0";} else {$GMIC1="";}
    if ($EDGESMOOTH) 
        {$GMIC2="-fx_dreamsmooth 10,0,1,0.8,0,0.8,0,24,0";} else {$GMIC2="";}
    $cmd="$GMIC -i $PIN -b 0.5 -n 0,1 -apply_gamma $EDGEGAMMA -n 0,255 $GMIC2 $GMIC1 -o $POUT $LOG2";
    verbose($cmd);
    print("--------> method 9 [edgegamma:$EDGEGAMMA] lce:$EDGELOCALCONTRAST smooth:$EDGESMOOTH]\n");
    system $cmd;
    if ($INVFINAL)
        {
        $cmd="$GMIC $POUT $GMICINV -o $POUT $LOG2";
        verbose($cmd);
        print("--------> inverting final\n");
        system $cmd;
        }
    #potrace
    $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$POTRACE $PIN -o $POUT -g -k $BLACKLEVEL";
    verbose($cmd);
    print("--------> potrace [blacklevel:$BLACKLEVEL]\n");
    system $cmd;
    #bug potrace
    $cmd="convert $POUT $OOUT";
    verbose($cmd);
    print("--------> potrace bug\n");
    system $cmd;
    }
  if ($METHOD == 10 || $METHOD == 0)
    {
    $OOUT="$OOUTDIR/$OUT\_m10.$ii.$EXT";
    $I=1;
    $cmd="$GMIC $IIN -o $WORKDIR/$I.ppm $LOG2";
    verbose($cmd);
    system $cmd;
    $PIN="$WORKDIR/$I.ppm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$COLORED $PIN $POUT";
    verbose($cmd);
    print("--------> ColorED\n");
    system $cmd;
    #--> output
    $cmd="$GMIC -i $POUT -to_colormode 3 -o $OOUT $LOG2";
    verbose($cmd);
    system $cmd;
    if ($INVFINAL)
        {
        $cmd="$GMIC $OOUT $GMICINV -o $OOUT $LOG2";
        verbose($cmd);
        print("--------> inverting final\n");
        system $cmd;
        }
    }
  if ($METHOD == 11 || $METHOD == 0)
    {
    $OOUT="$OOUTDIR/$OUT\_m11.$ii.$EXT";
    $I=1;
    $cmd="$GMIC $IIN -to_colormode 1 -o $WORKDIR/$I.pgm $LOG2";
    verbose($cmd);
    system $cmd;
    $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$EDPF $PIN $POUT";
    verbose($cmd);
    print("--------> Grayscale ED ParameterFree\n");
    system $cmd;
    #--> output
    $cmd="$GMIC -i $POUT -to_colormode 3 -o $OOUT $LOG2";
    verbose($cmd);
    system $cmd;
    if ($INVFINAL)
        {
        $cmd="$GMIC $OOUT $GMICINV -o $OOUT $LOG2";
        verbose($cmd);
        print("--------> inverting final\n");
        system $cmd;
        }
    }
  if ($PRINT)
    {
    $val=sprintf("%.02f",${$KEYNAME});
    $printcmd="$GMIC -i $OOUT -text_outline \"$KEYNAME...$val\" -o $OOUT $LOG2";
    verbose($printcmd);
    system "$printcmd";
    }
  if ($CLEAN)
    {
    $cleancmd="rm -r $WORKDIR";
    verbose($cleancmd);
    system $cleancmd;
    }
  #-----------------------------#
  ($s2,$m2,$h2)=localtime(time);
  ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
  print BOLD YELLOW "Writing $OUTDIR/$OUT.$ii.$EXT took $hlat:$mlat:$slat\n";print RESET;
  #-----------------------------#
  }
}

# gestion des keyframes
sub keyframe {
    @keyvals = split(/,/,$_[0]);
    #print "keyvals = @keyvals\n";
    $key1=$keyvals[0];
    $key2=$keyvals[1];
    return $key1+$keycount*(($key2-$key1)/$KEYFRAME);
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

sub json {
$CMD="EDGES";
$FRAMESINC=1;
$PARSER="perl";
$SERVICE="perl";
$OFFLINE="true";

$WORKINGDIR=$CWD;
$BLOCKNAME="$OUT\_$SHOT";
$JOBNAME="$scriptname\_$OUT\_$SHOT";
    
if ($OUT_USE_SHOT)
    {
    $COMMAND="$CMD.pl -conf $CONF -f @#@ @#@ $SKIP -shot $SHOT";
    $FILES="$OUTDIR/$SHOT/$OUT\_m$METHOD.\@####\@.$EXTOUT";
    }
else
    {
    $COMMAND="$CMD.pl -conf $CONF -f @#@ @#@ $SKIP";
    $FILES="$OUTDIR/$OUT\_m$METHOD.\@####\@.$EXTOUT";
    }
$HOSTNAME = `hostname -s`;
chop $HOSTNAME;
$USERNAME =  $ENV{'USER'}; 

$JSON="{\"job\":{\"blocks\":[{\"command\":\"$COMMAND\",\"files\":[\"$FILES\"],\"flags\":1,\"frame_first\":$FSTART,\"frame_last\":$FEND,\"frames_inc\":1,\"frames_per_task\":$FPT,\"name\":\"$BLOCKNAME\",\"parser\":\"$PARSER\",\"service\":\"$SERVICE\",\"capacity\":$CAPACITY,\"working_directory\":\"$WORKINGDIR\"}],\"host_name\":\"$HOSTNAME\",\"name\":\"$JOBNAME\",\"offline\":$OFFLINE,\"user_name\":\"$USERNAME\"}}";

print "$JSON\n";;
$JSONFILE="./cgru.json";
open( JSON , '>', $JSONFILE);
print JSON $JSON;
close JSON;

$sendcmd="afcmd json send $JSONFILE";
print "$sendcmd\n";
system $sendcmd;
$clean="rm $JSONFILE";
print "$clean\n";
system $clean;
}

sub xml {
$SCENENAME=getcwd;
$LAYER="$PROJECT\_$OUT\_$SHOT";
if ($OUT_USE_SHOT)
    {
    $OUTPUT="$SHOT/$OUT\_m$METHOD.";
    }
else
    {
    $OUTPUT="$OUT\_m$METHOD.";
    }

print XML "<Job>\n";
print XML "  <IsActive> true </IsActive>\n";
print XML "  <SceneName>   $SCENENAME/$CONF      </SceneName>\n";
print XML "  <SceneDatabaseDir>  $SCENENAME   </SceneDatabaseDir>\n";
print XML "  <Software>     edges     </Software>\n";
print XML "  <SeqStart>     $FSTART     </SeqStart>\n";
print XML "  <SeqEnd>      $FEND     </SeqEnd>\n";
print XML "  <Layer>    $LAYER      </Layer>\n";
print XML "  <ImageDir>   $OUTDIR/    </ImageDir>\n";
print XML "  <ImageFilename>     $OUTPUT     </ImageFilename>\n";
print XML "  <ImageExtension>     .$EXTOUT     </ImageExtension>\n";
print XML "  <ImageFramePadding>     4     </ImageFramePadding>\n";
print XML "  <CustomA>     $SHOT     </CustomA>\n";
print XML "</Job>\n";
}
