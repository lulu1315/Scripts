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
$EQUALIZEMIN="20%";
$EQUALIZEMAX="80%";
$ROLLING=0;
$INBLUR=0;
$DOBILATERAL=0;
$BILATERALSPATIAL=5;
$BILATERALVALUE=5;
$BILATERALITER=1;
$BRIGHTNESS=0;
$CONTRAST=0;
$GAMMA=0;
$SATURATION=0;
#edges params
$SIZE=0;
$METHOD=8;
#0 : all
#1 : hed
#2 : canny deriche (pink)
$ALPHA=.5;
#3 : gradient norm
$NORMALIZE=1;
#4 : watershed
$CONNEX=8;
#5 : lulu method with potrace
$NITERS=8;
$EDGEGAMMA=1.5;
$EDGELOCALCONTRAST=1;
#6 : ColorEDPF
$CEDGRADTRESH=24;  #ED et EDV
$CEDANCHORTRESH=4; #ED
$CEDSIGMA=1.5; #ALLMODES
$CEDMODE=2;    #0:ED 1:EDV 2:EDPF
#7 : GrayScaleED(PF) et CannySR(PF)
$GSGRADTRESH=24;  
$GSANCHORTRESH=4; 
$GSSIGMA=1; 
$CANNYLOW=40;
$CANNYHIGH=80;
$GSMODE=1;     #0:ED #1:EDPF #2:CannySR #3:CannySRPF
#8 : CEDContours
$CEDCGRADTRESH=20;  
$CEDCCUTOFFTRESH=200;  
$CEDCMODE=1;  #0:Soft #1:Hard
#9 : GEDContours
$GEDCGRADTRESH=32;  
$GEDCCUTOFFTRESH=200;  
$GEDCMODE=0;  #0:Soft #1:Hard
#10 DLIB sobel + suppress non maximumedge
$DLIBSTYLE=0; #0 b/w 1:heatmap 2:jet
#11 Coherent Line Drawing
$CLDTANGENTDIR="$CWD/gradient";
$CLDTANGENT="tangent";
$CLDFDOGITERATION=3;
$CLDSIGMAM=2;
$CLDSIGMAC=1;
$CLDRHO=.995;
$CLDTAU=.99;
#post process
$DOPEL=0;
$DOPELPLY=0;
$PELMINSEGLENGTH=8;
$DILATE=0;
$EDGESMOOTH=0;
$DOPOTRACE=0;
$BLACKLEVEL=.15;
$DODESPECKLE=0;
$DESPECKLEMAXAREA=5;
$DESPECKLETOLERANCE=30;
$INVFINAL=0;
#flags
$PARAMS="";
$KEEPINPUT=0;
$CLEAN=1;
$GPU=0;
$CSV=0;
$LOG1=">/var/tmp/$scriptname.log";
$LOG2="2>/var/tmp/$scriptname.log";
#JSON
$CAPACITY=250;
$SKIP="-force";
$FPT=5;

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
print AUTOCONF confstr(EQUALIZEMIN);
print AUTOCONF confstr(EQUALIZEMAX);
print AUTOCONF confstr(ROLLING);
print AUTOCONF confstr(INBLUR);
print AUTOCONF confstr(DOBILATERAL);
print AUTOCONF confstr(BILATERALSPATIAL);
print AUTOCONF confstr(BILATERALVALUE);
print AUTOCONF confstr(BILATERALITER);
print AUTOCONF confstr(BRIGHTNESS);
print AUTOCONF confstr(CONTRAST);
print AUTOCONF confstr(GAMMA);
print AUTOCONF confstr(SATURATION);
print AUTOCONF "#edges params\n";
print AUTOCONF confstr(SIZE);
print AUTOCONF confstr(METHOD);
print AUTOCONF "#0 : all\n";
print AUTOCONF "#1 : HED\n";
print AUTOCONF "#2 : Canny Deriche\n";
print AUTOCONF confstr(ALPHA);
print AUTOCONF "#3 : GradientNorm\n";
print AUTOCONF confstr(NORMALIZE);
print AUTOCONF "#4 : Watershed\n";
print AUTOCONF confstr(CONNEX);
print AUTOCONF "#5 : lulu with potrace\n";
print AUTOCONF confstr(NITERS);
print AUTOCONF confstr(EDGEGAMMA);
print AUTOCONF confstr(EDGELOCALCONTRAST);
print AUTOCONF "#6 : ColorED(PF)(V)\n";
print AUTOCONF "#ED: EdgeDrawing \n";
print AUTOCONF "#PF: ParameterFree \n";
print AUTOCONF "#V:  EdgeSegmentValidation \n";
print AUTOCONF "#ColorED mode -> 0:ED 1:EDV 2:EDPF\n";
print AUTOCONF confstr(CEDGRADTRESH);
print AUTOCONF confstr(CEDANCHORTRESH);
print AUTOCONF confstr(CEDSIGMA);
print AUTOCONF confstr(CEDMODE);
print AUTOCONF "#7 : GrayscaleED(PF) ou CannySR(PF)\n";
print AUTOCONF confstr(GSGRADTRESH);
print AUTOCONF confstr(GSANCHORTRESH);
print AUTOCONF confstr(CANNYLOW);
print AUTOCONF confstr(CANNYHIGH);
print AUTOCONF confstr(GSSIGMA);
print AUTOCONF confstr(GSMODE);
print AUTOCONF "#GrayScaleED mode -> 0:ED 1:EDPF 2:CannySR 3:CannySRPF\n";
print AUTOCONF "#8 : CEDContours\n";
print AUTOCONF confstr(CEDCGRADTRESH);
print AUTOCONF confstr(CEDCCUTOFFTRESH);
print AUTOCONF confstr(CEDCMODE);
print AUTOCONF "#CEDContours mode -> 0:Soft 1:Hard\n";
print AUTOCONF "#9 : GEDContours\n";
print AUTOCONF confstr(GEDCGRADTRESH);
print AUTOCONF confstr(GEDCCUTOFFTRESH);
print AUTOCONF confstr(GEDCMODE);
print AUTOCONF "#GEDContours mode -> 0:Soft 1:Hard\n";
print AUTOCONF "#10 : DLIB sobel+maxima\n";
print AUTOCONF confstr(DLIBSTYLE);
print AUTOCONF "#0:bw 1:heatmap 2:jet\n";
print AUTOCONF "#11 : Coherent Line Drawing (CLD)\n";
print AUTOCONF confstr(CLDTANGENTDIR);
print AUTOCONF confstr(CLDTANGENT);
print AUTOCONF confstr(CLDFDOGITERATION);
print AUTOCONF confstr(CLDSIGMAM);
print AUTOCONF confstr(CLDSIGMAC);
print AUTOCONF confstr(CLDRHO);
print AUTOCONF confstr(CLDTAU);
print AUTOCONF "#12 : globalPg\n";
print AUTOCONF "#postprocess\n";
print AUTOCONF confstr(DOPEL);
print AUTOCONF confstr(DOPELPLY);
print AUTOCONF confstr(PELMINSEGLENGTH);
print AUTOCONF confstr(DILATE);
print AUTOCONF confstr(EDGESMOOTH);
print AUTOCONF confstr(DOPOTRACE);
print AUTOCONF confstr(BLACKLEVEL);
print AUTOCONF confstr(DODESPECKLE);
print AUTOCONF confstr(DESPECKLEMAXAREA);
print AUTOCONF confstr(DESPECKLETOLERANCE);
print AUTOCONF confstr(INVFINAL);
print AUTOCONF "#misc\n";
print AUTOCONF confstr(PARAMS);
print AUTOCONF confstr(KEEPINPUT);
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
	print "-m method[8]\n";
	print "-zeropad4 [1]\n";
	print "-force [0]\n";
	print "-verbose\n";
	print "-gpu [0]\n";
    print "-csv csv_file.csv\n";
	print "-json [submit to afanasy]\n";	
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
    require "./$CONF";
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
  if (@ARGV[$arg] eq "-m") 
    {
    $METHOD=@ARGV[$arg+1];
    print "method : $METHOD\n";
    }
  if (@ARGV[$arg] eq "-cld") 
    {
    $CLDFDOGITERATION=@ARGV[$arg+1];
    $CLDSIGMAM=@ARGV[$arg+2];
    $CLDSIGMAC=@ARGV[$arg+3];
    $CLDRHO=@ARGV[$arg+4];
    print BOLD BLUE "cld [iter:$CLDFDOGITERATION sigmam:$CLDSIGMAM sigmac:$CLDSIGMAC rho:$CLDRHO]\n";print RESET;
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
  $HED="python /shared/foss/hed/examples/hed/make_hed.py";
  $PINKBIN="/shared/foss/Pink/linux/bin";
  $POTRACE="/usr/bin/potrace";
  $COLORED="/shared/foss/ED/ColorED/ColorEDTest";
  $EDPF="/shared/foss/ED/ED/EDTest";
  $PEL="/shared/foss/ED/PEL/PEL";
  $PELTEXT="/shared/foss/ED/PELtext/PEL";
  $CEDCONTOURS="/shared/foss/ED/CEDContours/CEDContoursTest";
  $GEDCONTOURS="/shared/foss/ED/GEDContours/GEDContoursTest";
  $DLIB="/shared/foss/dlib-19.16/lulu_examples/build/edge_detector";
  $CLD="/shared/foss/Coherent-Line-Drawing/build/CLD-cli";
  $CLDOFLOW="/shared/foss/Coherent-Line-Drawing/build/CLD-oflow-cli";
  $ENV{PYTHONPATH} = "/shared/foss/hed/python:$ENV{'PYTHONPATH'}";
  $ENV{PATH} = "/shared/foss/Pink/linux/bin:$ENV{'PATH'}";
  }
  
$userName =  $ENV{'USER'}; 
if ($userName eq "dev18")	#
  {
  $GMIC="/usr/bin/gmic";
  $HED="python3 /shared/foss-18/pytorch-hed/run.py";
  $PINKBIN="/shared/foss-18/Pink/linux/bin";
  $POTRACE="/usr/bin/potrace";
  $COLORED="/shared/foss-18/ED/ColorED/ColorEDTest";
  $EDPF="/shared/foss-18/ED/ED/EDTest";
  $PEL="/shared/foss-18/ED/PEL/PEL";
  $PELTEXT="/shared/foss-18/ED/PELtext/PEL";
  $CEDCONTOURS="/shared/foss-18/ED/CEDContours/CEDContoursTest";
  $GEDCONTOURS="/shared/foss-18/ED/GEDContours/GEDContoursTest";
  $DLIB="/shared/foss-18/dlib-19.16/lulu_examples/build/edge_detector";
  $CLD="/shared/foss-18/Coherent-Line-Drawing/build/CLD-cli";
  $CLDOFLOW="/shared/foss-18/Coherent-Line-Drawing/build/CLD-oflow-cli";
  $GPB="/shared/foss-18/gPb-GSoC/opencv_gpb/build/gpb_main";
  $ENV{PATH} = "/shared/foss-18/Pink/linux/bin:$ENV{'PATH'}";
  $ENV{LD_LIBRARY_PATH} = "/shared/foss-18/ED/ED:$ENV{'LD_LIBRARY_PATH'}";
  }
  
sub edges {

#$PARAMS="_i$CLDFDOGITERATION\_sm$CLDSIGMAM\_sc$CLDSIGMAC\_rho$CLDRHO";
if ($INVFINAL) 
    {$GMICINV = "-n 0,1 -oneminus -n 0,255";} else {$GMICINV = "";}
if ($VERBOSE) {$LOG1="";$LOG2="";}

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
    {
    $OOUT="$OOUTDIR/$OUT$PARAMS\_m$METHOD.$ii.$EXT";
    }
else
    {
    $OOUT="$OOUTDIR/$OUT$PARAMS\_m1.$ii.$EXT";
    }
    
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
        {$GMIC5="-equalize 256,$EQUALIZEMIN,$EQUALIZEMAX";} 
    else {$GMIC5="";}
  if ($BRIGHTNESS || $CONTRAST || $GAMMA || $SATURATION) 
        {$GMIC3="-fx_adjust_colors $BRIGHTNESS,$CONTRAST,$GAMMA,0,$SATURATION";} 
    else {$GMIC3="";}
    if ($SIZE) 
        {$GMIC4="-resize2dx $SIZE,5";} 
  if ($INBLUR) 
        {$GMIC6="-blur $INBLUR";} 
    else {$GMIC6="";}
  if ($DOBILATERAL) 
        {$GMIC7="-fx_smooth_bilateral $BILATERALSPATIAL,$BILATERALVALUE,$BILATERALITER,0,0";} 
    else {$GMIC7="";}
  $cmd="$GMIC -i $IIN -to_colormode 3 $GMIC5 $GMIC4 $GMIC1 $GMIC2 $GMIC3 $GMIC6 $GMIC7 -o $WORKDIR/$I.png $LOG2";
  verbose($cmd);
  print("--------> preprocess input [size:$SIZE equalize:$EQUALIZE lce:$DOLOCALCONTRAST rolling:$ROLLING blur:$INBLUR bilateral:$DOBILATERAL,$BILATERALSPATIAL,$BILATERALVALUE,$BILATERALITER bcgs:$BRIGHTNESS/$CONTRAST/$GAMMA/$SATURATION]\n");
  system $cmd;
  $tmpcmd="cp $IIN $WORKDIR/0.png";
  system $tmpcmd;
  $IIN="$WORKDIR/$I.png";
  $OOUT="$OOUTDIR/$OUT\_input.$ii.$EXT";
  if ($KEEPINPUT)
    {
    $cmd="cp $IIN $OOUT";
    verbose($cmd);
    print("--------> keeping input $OOUT\n");
    system $cmd;
    }
  if ($METHOD == 1 || $METHOD == 0)
    {
    $OOUT="$OOUTDIR/$OUT$PARAMS\_m1.$ii.$EXT";
    $I=1;
    #$cmd="$HED --image_in $IIN --image_out=$IIN --gpu_id $GPU 2>/var/tmp/$scriptname.log";
    $cmd="$HED --model bsds500 --in $IIN --out $WORKDIR/$I.pgm";
    verbose($cmd);
    #system $cmd;
    #$cmd="$GMIC -i $WORKDIR/$I.tiff -mul 255 -to_colormode 3 -o $OOUT $LOG2";
    #verbose($cmd);
    print("--------> HED\n");
    system $cmd;
    if ($DOPOTRACE)
        {
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
    else
        {
        #--> output
        $cmd="$GMIC -i $WORKDIR/$I.pgm -to_colormode 3 -o $OOUT $LOG2";
        verbose($cmd);
        system $cmd;
        }
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
    $OOUT="$OOUTDIR/$OUT$PARAMS\_m2.$ii.$EXT";
    $I=1;
    $cmd="$GMIC $IIN -to_colormode 1 -o $WORKDIR/$I.pgm $LOG2";
    verbose($cmd);
    system $cmd;
    $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$PINKBIN/gradientcd $PIN $ALPHA $POUT";
    verbose($cmd);
    print("--------> Canny Deriche [alpha:$ALPHA]\n");
    system $cmd;
    if ($NORMALIZE) {$GMIC1="-n 0,255";} else {$GMIC1="";}
    print("--------> [normalized:$NORMALIZE]\n");
    #--> formatting gradient
    $cmd="$GMIC -i $POUT $GMIC1 -to_colormode 3 -o $POUT $LOG2";
    verbose($cmd);
    system $cmd;
    if ($DOPOTRACE)
        {
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
    else
        {
        #--> output
        $cmd="$GMIC -i $POUT -to_colormode 3 -o $OOUT $LOG2";
        verbose($cmd);
        system $cmd;
        }
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
    $OOUT="$OOUTDIR/$OUT$PARAMS\_m3.$ii.$EXT";
    $I=1;
    $cmd="$GMIC $IIN -o $WORKDIR/$I.ppm $LOG2";
    verbose($cmd);
    system $cmd;
    $PIN="$WORKDIR/$I.ppm";$I++;$POUT="$WORKDIR/$I.pgm";
    if ($NORMALIZE) {$GMIC1="-n 0,255";} else {$GMIC1="";}
    $cmd="$GMIC -i $PIN -gradient_norm $GMIC1 -o $POUT $LOG2";
    verbose($cmd);
    print("--------> gmic gradient_norm [normalized:$NORMALIZE]\n");
    system $cmd;
    #do PEL
    if ($DOPEL)
        {
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        if ($DOPELPLY)
            {
            $OOUTPLY="$OOUTDIR/$OUT\_m$METHOD.$ii.ply";
            $cmd="$PELTEXT $PIN $POUT $OOUTPLY $PELMINSEGLENGTH";
            print("--------> PEL + PEL ply [min seg length:$PELMINSEGLENGTH]\n");
            }
        else
            {
            $cmd="$PEL $PIN $POUT $PELMINSEGLENGTH";
            print("--------> PEL [min seg length:$PELMINSEGLENGTH]\n");
            }
        verbose($cmd);
        system $cmd;
        }
    if ($DILATE)
        {
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        $cmd="$GMIC $PIN -dilate_circ $DILATE -b 1 -o $POUT $LOG2";
        verbose($cmd);
        print("--------> dilate_circ [dilate:$DILATE]\n");
        system $cmd;
        }
    if ($EDGESMOOTH) 
        {
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        $cmd="$GMIC $PIN -fx_dreamsmooth 10,0,1,0.8,0,0.8,0,24,0 -o $POUT $LOG2";
        verbose($cmd);
        print("--------> dreamsmooth\n");
        system $cmd;
        }
    if ($DOPOTRACE)
        {
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
    else
        {
        #--> output
        $cmd="$GMIC -i $POUT -to_colormode 3 -o $OOUT $LOG2";
        verbose($cmd);
        system $cmd;
        }
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
    $OOUT="$OOUTDIR/$OUT$PARAMS\_m4.$ii.$EXT";
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
  if ($METHOD == 5 || $METHOD == 0)
    {
    $OOUT="$OOUTDIR/$OUT$PARAMS\_m5.$ii.$EXT";
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
    print("--------> method 5 [edgegamma:$EDGEGAMMA] lce:$EDGELOCALCONTRAST smooth:$EDGESMOOTH]\n");
    system $cmd;
    if ($INVFINAL)
        {
        $cmd="$GMIC $POUT $GMICINV -o $POUT $LOG2";
        verbose($cmd);
        print("--------> inverting final\n");
        system $cmd;
        }
    if ($DOPOTRACE)
        {
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
    else
        {
        $cmd="cp $POUT $OOUT";
        verbose($cmd);
        system $cmd;
        }
    }
  if ($METHOD == 6 || $METHOD == 0 || $METHOD == 6789)
    {
    $OOUT="$OOUTDIR/$OUT$PARAMS\_m6.$ii.$EXT";
    $I=1;
    $cmd="$GMIC $IIN -o $WORKDIR/$I.ppm $LOG2";
    verbose($cmd);
    system $cmd;
    $PIN="$WORKDIR/$I.ppm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$COLORED $PIN $POUT $CEDGRADTRESH $CEDANCHORTRESH $CEDSIGMA $CEDMODE";
    verbose($cmd);
    #ColorED mode -> 0:ED 1:EDV 2:EDPF\n";
    if ($CEDMODE == 0){$modename="ColorED";}
    if ($CEDMODE == 1){$modename="ColorED with Validation";}
    if ($CEDMODE == 2){$modename="ColorED ParameterFree";}
    print("--------> $modename [mode:$CEDMODE gradtresh:$CEDGRADTRESH anchortresh:$CEDANCHORTRESH sigma:$CEDSIGMA]\n");
    system $cmd;
    #do PEL
    if ($DOPEL)
        {
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        if ($DOPELPLY)
            {
            $OOUTPLY="$OOUTDIR/$OUT\_m$METHOD.$ii.ply";
            $cmd="$PELTEXT $PIN $POUT $OOUTPLY $PELMINSEGLENGTH";
            print("--------> PEL + PEL ply [min seg length:$PELMINSEGLENGTH]\n");
            }
        else
            {
            $cmd="$PEL $PIN $POUT $PELMINSEGLENGTH";
            print("--------> PEL [min seg length:$PELMINSEGLENGTH]\n");
            }
        verbose($cmd);
        system $cmd;
        }
    if ($DILATE)
        {
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        $cmd="$GMIC $PIN -dilate_circ $DILATE -b 1 -o $POUT $LOG2";
        verbose($cmd);
        print("--------> dilate_circ [dilate:$DILATE]\n");
        system $cmd;
        }
    if ($EDGESMOOTH) 
        {
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        $cmd="$GMIC $PIN -fx_dreamsmooth 10,0,1,0.8,0,0.8,0,24,0 -o $POUT $LOG2";
        verbose($cmd);
        print("--------> dreamsmooth\n");
        system $cmd;
        }
    if ($DOPOTRACE)
        {
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
    else
        {
        #--> output
        $cmd="$GMIC -i $POUT -to_colormode 3 -o $OOUT $LOG2";
        verbose($cmd);
        system $cmd;
        }
    if ($INVFINAL)
        {
        $cmd="$GMIC $OOUT $GMICINV -o $OOUT $LOG2";
        verbose($cmd);
        print("--------> inverting final\n");
        system $cmd;
        }
    }
  if ($METHOD == 7 || $METHOD == 0 || $METHOD == 6789)
    {
    $OOUT="$OOUTDIR/$OUT$PARAMS\_m7.$ii.$EXT";
    #$OOUT="$OOUTDIR/$OUT\_m7_mode$GSMODE.$ii.$EXT";
    $I=1;
    $cmd="$GMIC $IIN -to_colormode 1 -o $WORKDIR/$I.pgm $LOG2";
    verbose($cmd);
    system $cmd;
    $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$EDPF $PIN $POUT $GSGRADTRESH $GSANCHORTRESH $GSSIGMA $CANNYLOW $CANNYHIGH $GSMODE >/var/tmp/$scriptname.log";
    verbose($cmd);
    #GrayScaleED mode -> 0:ED 1:EDPF 2:CannySR 3:CannySRPF
    if ($GSMODE == 0){$modename="GrayscaleED";}
    if ($GSMODE == 1){$modename="GrayscaleED ParameterFree";}
    if ($GSMODE == 2){$modename="CannySR";}
    if ($GSMODE == 3){$modename="CannySR ParameterFree";}
    print("--------> $modename [mode:$GSMODE gradtresh:$GSGRADTRESH anchortresh:$GSANCHORTRESH sigma:$GSSIGMA cannylow:$CANNYLOW cannyhigh:$CANNYHIGH]\n");
    system $cmd;
    if ($DOPEL)
        {
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        if ($DOPELPLY)
            {
            $OOUTPLY="$OOUTDIR/$OUT\_m$METHOD.$ii.ply";
            $cmd="$PELTEXT $PIN $POUT $OOUTPLY $PELMINSEGLENGTH";
            print("--------> PEL + PEL ply [min seg length:$PELMINSEGLENGTH]\n");
            }
        else
            {
            $cmd="$PEL $PIN $POUT $PELMINSEGLENGTH";
            print("--------> PEL [min seg length:$PELMINSEGLENGTH]\n");
            }
        verbose($cmd);
        system $cmd;
        }
     if ($DILATE)
        {
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        $cmd="$GMIC $PIN -dilate_circ $DILATE -b 1 -o $POUT $LOG2";
        verbose($cmd);
        print("--------> dilate_circ [dilate:$DILATE]\n");
        system $cmd;
        }
    if ($EDGESMOOTH) 
        {
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        $cmd="$GMIC $PIN -fx_dreamsmooth 10,0,1,0.8,0,0.8,0,24,0 -o $POUT $LOG2";
        verbose($cmd);
        print("--------> dreamsmooth\n");
        system $cmd;
        }
    if ($DOPOTRACE)
        {
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
    else
        {
        #--> output
        $cmd="$GMIC -i $POUT -to_colormode 3 -o $OOUT $LOG2";
        verbose($cmd);
        system $cmd;
        }
    if ($INVFINAL)
        {
        $cmd="$GMIC $OOUT $GMICINV -o $OOUT $LOG2";
        verbose($cmd);
        print("--------> inverting final\n");
        system $cmd;
        }
    }
  if ($METHOD == 8 || $METHOD == 0 || $METHOD == 6789)
    {
    $OOUT="$OOUTDIR/$OUT$PARAMS\_m8.$ii.$EXT";
    $I=1;
    $cmd="$GMIC $IIN -o $WORKDIR/$I.ppm $LOG2";
    verbose($cmd);
    system $cmd;
    $PIN="$WORKDIR/$I.ppm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$CEDCONTOURS $PIN $POUT $CEDCGRADTRESH $CEDCCUTOFFTRESH $CEDCMODE >/var/tmp/$scriptname.log";
    verbose($cmd);
    if ($CEDCMODE == 0){$modename="CEDContours Soft";}
    if ($CEDCMODE == 1){$modename="CEDContours Hard";}
    print("--------> $modename [mode:$CEDCMODE gradtresh:$CEDCGRADTRESH cutofftresh:$CEDCCUTOFFTRESH]\n");
    system $cmd;
    #do PEL
    if ($DOPEL)
        {
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        if ($DOPELPLY)
            {
            $OOUTPLY="$OOUTDIR/$OUT\_m$METHOD.$ii.ply";
            $cmd="$PELTEXT $PIN $POUT $OOUTPLY $PELMINSEGLENGTH";
            print("--------> PEL + PEL ply [min seg length:$PELMINSEGLENGTH]\n");
            }
        else
            {
            $cmd="$PEL $PIN $POUT $PELMINSEGLENGTH";
            print("--------> PEL [min seg length:$PELMINSEGLENGTH]\n");
            }
        verbose($cmd);
        system $cmd;
        }
    if ($DILATE)
        {
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        $cmd="$GMIC $PIN -dilate_circ $DILATE -b 1 -o $POUT $LOG2";
        verbose($cmd);
        print("--------> dilate_circ [dilate:$DILATE]\n");
        system $cmd;
        }
    if ($EDGESMOOTH) 
        {
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        $cmd="$GMIC $PIN -fx_dreamsmooth 10,0,1,0.8,0,0.8,0,24,0 -o $POUT $LOG2";
        verbose($cmd);
        print("--------> dreamsmooth\n");
        system $cmd;
        }
    if ($DOPOTRACE)
        {
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
    else
        {
        #--> output
        $cmd="$GMIC -i $POUT -to_colormode 3 -o $OOUT $LOG2";
        verbose($cmd);
        system $cmd;
        }
    if ($INVFINAL)
        {
        $cmd="$GMIC $OOUT $GMICINV -o $OOUT $LOG2";
        verbose($cmd);
        print("--------> inverting final\n");
        system $cmd;
        }
    }
  if ($METHOD == 9 || $METHOD == 0 || $METHOD == 6789)
    {
    $OOUT="$OOUTDIR/$OUT$PARAMS\_m9.$ii.$EXT";
    #$OOUT="$OOUTDIR/$OUT\_m7_mode$GSMODE.$ii.$EXT";
    $I=1;
    $cmd="$GMIC $IIN -to_colormode 1 -o $WORKDIR/$I.pgm $LOG2";
    verbose($cmd);
    system $cmd;
    $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$GEDCONTOURS $PIN $POUT $GEDCGRADTRESH $GEDCCUTOFFTRESH $GEDCMODE >/var/tmp/$scriptname.log";
    verbose($cmd);
    #GrayScaleED mode -> 0:ED 1:EDPF 2:CannySR 3:CannySRPF
    if ($GEDCMODE == 0){$modename="GEDContours Soft";}
    if ($GEDCMODE == 1){$modename="GEDContours Hard";}
    print("--------> $modename [mode:$GEDCMODE gradtresh:$GEDCGRADTRESH cutofftresh:$GEDCCUTOFFTRESH]\n");
    system $cmd;
    if ($DOPEL)
        {
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        if ($DOPELPLY)
            {
            $OOUTPLY="$OOUTDIR/$OUT\_m$METHOD.$ii.ply";
            $cmd="$PELTEXT $PIN $POUT $OOUTPLY $PELMINSEGLENGTH";
            print("--------> PEL + PEL ply [min seg length:$PELMINSEGLENGTH]\n");
            }
        else
            {
            $cmd="$PEL $PIN $POUT $PELMINSEGLENGTH";
            print("--------> PEL [min seg length:$PELMINSEGLENGTH]\n");
            }
        verbose($cmd);
        system $cmd;
        }
     if ($DILATE)
        {
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        $cmd="$GMIC $PIN -dilate_circ $DILATE -b 1 -o $POUT $LOG2";
        verbose($cmd);
        print("--------> dilate_circ [dilate:$DILATE]\n");
        system $cmd;
        }
    if ($EDGESMOOTH) 
        {
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        $cmd="$GMIC $PIN -fx_dreamsmooth 10,0,1,0.8,0,0.8,0,24,0 -o $POUT $LOG2";
        verbose($cmd);
        print("--------> dreamsmooth\n");
        system $cmd;
        }
    if ($DOPOTRACE)
        {
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
    else
        {
        #--> output
        $cmd="$GMIC -i $POUT -to_colormode 3 -o $OOUT $LOG2";
        verbose($cmd);
        system $cmd;
        }
    if ($INVFINAL)
        {
        $cmd="$GMIC $OOUT $GMICINV -o $OOUT $LOG2";
        verbose($cmd);
        print("--------> inverting final\n");
        system $cmd;
        }
    }
  if ($METHOD == 10 || $METHOD == 0)
    {
    $OOUT="$OOUTDIR/$OUT$PARAMS\_m10.$ii.$EXT";
    $I=1;
    $cmd="$GMIC $IIN -to_colormode 1 -o $WORKDIR/$I.png $LOG2";
    verbose($cmd);
    system $cmd;
    $PIN="$WORKDIR/$I.png";$I++;$POUT="$WORKDIR/$I.png";
    $cmd="$DLIB $PIN $POUT $DLIBSTYLE >/var/tmp/$scriptname.log";
    verbose($cmd);
    print("--------> dlib sobel [style:$DLIBSTYLE]\n");
    system $cmd;
     if ($DILATE)
        {
        $PIN="$WORKDIR/$I.png";$I++;$POUT="$WORKDIR/$I.png";
        $cmd="$GMIC $PIN -dilate_circ $DILATE -b 1 -o $POUT $LOG2";
        verbose($cmd);
        print("--------> dilate_circ [dilate:$DILATE]\n");
        system $cmd;
        }
    if ($EDGESMOOTH) 
        {
        $PIN="$WORKDIR/$I.png";$I++;$POUT="$WORKDIR/$I.png";
        $cmd="$GMIC $PIN -fx_dreamsmooth 10,0,1,0.8,0,0.8,0,24,0 -o $POUT $LOG2";
        verbose($cmd);
        print("--------> dreamsmooth\n");
        system $cmd;
        }
    if ($DOPOTRACE)
        {
        #convert to pgm
        $PIN="$WORKDIR/$I.png";$I++;$POUT="$WORKDIR/$I.pgm";
        $cmd="$GMIC -i $PIN -o $POUT $LOG2";
        verbose($cmd);
        print("--------> gmic : convert to pgm for potrace\n");
        system $cmd;
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
    else
        {
        #--> output
        $cmd="$GMIC -i $POUT -to_colormode 3 -o $OOUT $LOG2";
        verbose($cmd);
        system $cmd;
        }
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
    $OOUT="$OOUTDIR/$OUT$PARAMS\_m11.$ii.$EXT";
    $EDGEFLOWIN="$CLDTANGENTDIR/$SHOT/$CLDTANGENT.$ii.exr";
    $I=1;
    $cmd="$GMIC $IIN -to_colormode 1 -o $WORKDIR/$I.png $LOG2";
    verbose($cmd);
    system $cmd;
    $PIN="$WORKDIR/$I.png";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$CLD $IIN $EDGEFLOWIN $CLDFDOGITERATION $CLDSIGMAM $CLDSIGMAC $CLDRHO $CLDTAU $POUT";
    verbose($cmd);
    print("--------> Coherent Line Drawing [DogF iter:$CLDFDOGITERATION sigma_m:$CLDSIGMAM sigma_c:$CLDSIGMAC rho:$CLDRHO tau:$CLDTAU]\n");
    system $cmd;
    #do PEL
    if ($DOPEL)
        {
        #invert image
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        $cmd="$GMIC $PIN -n 0,1 -oneminus -n 0,255 -o $POUT $LOG2";
        verbose($cmd);
        print("--------> inverting for PEL\n");
        system $cmd;
        #thinning
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        $THINMETHOD=1;
        $cmd="$PINKBIN/skelpar $PIN $THINMETHOD -1 $POUT";
        verbose($cmd);
        print("--------> pink thinning [method:$THINMETHOD]\n");
        system $cmd;
        #
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        if ($DOPELPLY)
            {
            $OOUTPLY="$OOUTDIR/$OUT\_m$METHOD.$ii.ply";
            $cmd="$PELTEXT $PIN $POUT $OOUTPLY $PELMINSEGLENGTH";
            print("--------> PEL + PEL ply [min seg length:$PELMINSEGLENGTH]\n");
            }
        else
            {
            $cmd="$PEL $PIN $POUT $PELMINSEGLENGTH";
            print("--------> PEL [min seg length:$PELMINSEGLENGTH]\n");
            }
        verbose($cmd);
        system $cmd;
        }
     if ($DILATE)
        {
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        $cmd="$GMIC $PIN -dilate_circ $DILATE -b 1 -o $POUT $LOG2";
        verbose($cmd);
        print("--------> dilate_circ [dilate:$DILATE]\n");
        system $cmd;
        }
    if ($EDGESMOOTH) 
        {
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        $cmd="$GMIC $PIN -fx_dreamsmooth 10,0,1,0.8,0,0.8,0,24,0 -o $POUT $LOG2";
        verbose($cmd);
        print("--------> dreamsmooth\n");
        system $cmd;
        }
    if ($DOPOTRACE)
        {
        #convert to pgm
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        $cmd="$GMIC -i $PIN -o $POUT $LOG2";
        verbose($cmd);
        print("--------> gmic : convert to pgm for potrace\n");
        system $cmd;
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
    else
        {
        #--> output
        $cmd="$GMIC -i $POUT -to_colormode 3 -o $OOUT $LOG2";
        verbose($cmd);
        system $cmd;
        }
    if ($DODESPECKLE) 
        {
        $cmd="$GMIC $OOUT gcd_despeckle $DESPECKLETOLERANCE,$DESPECKLEMAXAREA -o $OOUT $LOG2";
        verbose($cmd);
        print("--------> despeckle [tolerance:$DESPECKLETOLERANCE max area:$DESPECKLEMAXAREA\n");
        system $cmd;
        }
    if ($INVFINAL)
        {
        $cmd="$GMIC $OOUT $GMICINV -o $OOUT $LOG2";
        verbose($cmd);
        print("--------> inverting final\n");
        system $cmd;
        }
    }
  if ($METHOD == 12 || $METHOD == 0)
    {
    $OOUT="$OOUTDIR/$OUT$PARAMS\_m12.$ii.$EXT";
    $OOUTUCM="$OOUTDIR/$OUT$PARAMS\_ucm.$ii.$EXT";
    $I=1;
    $PIN="$WORKDIR/$I.png";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$GPB $PIN $POUT $OOUTUCM";
    verbose($cmd);
    print("--------> globalPg\n");
    system $cmd;
    #do PEL
    if ($DOPEL)
        {
        #invert image
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        $cmd="$GMIC $PIN -n 0,1 -oneminus -n 0,255 -o $POUT $LOG2";
        verbose($cmd);
        print("--------> inverting for PEL\n");
        system $cmd;
        #thinning
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        $THINMETHOD=1;
        $cmd="$PINKBIN/skelpar $PIN $THINMETHOD -1 $POUT";
        verbose($cmd);
        print("--------> pink thinning [method:$THINMETHOD]\n");
        system $cmd;
        #
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        if ($DOPELPLY)
            {
            $OOUTPLY="$OOUTDIR/$OUT\_m$METHOD.$ii.ply";
            $cmd="$PELTEXT $PIN $POUT $OOUTPLY $PELMINSEGLENGTH";
            print("--------> PEL + PEL ply [min seg length:$PELMINSEGLENGTH]\n");
            }
        else
            {
            $cmd="$PEL $PIN $POUT $PELMINSEGLENGTH";
            print("--------> PEL [min seg length:$PELMINSEGLENGTH]\n");
            }
        verbose($cmd);
        system $cmd;
        }
     if ($DILATE)
        {
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        $cmd="$GMIC $PIN -dilate_circ $DILATE -b 1 -o $POUT $LOG2";
        verbose($cmd);
        print("--------> dilate_circ [dilate:$DILATE]\n");
        system $cmd;
        }
    if ($EDGESMOOTH) 
        {
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        $cmd="$GMIC $PIN -fx_dreamsmooth 10,0,1,0.8,0,0.8,0,24,0 -o $POUT $LOG2";
        verbose($cmd);
        print("--------> dreamsmooth\n");
        system $cmd;
        }
    if ($DOPOTRACE)
        {
        #convert to pgm
        $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
        $cmd="$GMIC -i $PIN -o $POUT $LOG2";
        verbose($cmd);
        print("--------> gmic : convert to pgm for potrace\n");
        system $cmd;
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
    else
        {
        #--> output
        $cmd="$GMIC -i $POUT -to_colormode 3 -o $OOUT $LOG2";
        verbose($cmd);
        system $cmd;
        }
    if ($DODESPECKLE) 
        {
        $cmd="$GMIC $OOUT gcd_despeckle $DESPECKLETOLERANCE,$DESPECKLEMAXAREA -o $OOUT $LOG2";
        verbose($cmd);
        print("--------> despeckle [tolerance:$DESPECKLETOLERANCE max area:$DESPECKLEMAXAREA\n");
        system $cmd;
        }
    if ($INVFINAL)
        {
        $cmd="$GMIC $OOUT $GMICINV -o $OOUT $LOG2";
        verbose($cmd);
        print("--------> inverting final\n");
        system $cmd;
        }
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
} #end edges

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
    $FIRSTFRAME=$FSTART;
    $LASTFRAME=$FEND;
    if ($process)
      {
      edges();
      }
    }
   }
else
  {
  edges();
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
