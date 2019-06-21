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
$SHOT="";
$INDIR="$CWD/originales";
$IN="ima";
$IN_USE_SHOT=0;
$OUTDIR="$CWD/$scriptname";
$OUT="ima";
$OUT_USE_SHOT=0;
$ZEROPAD=1;
$FORCE=0;
$EXT="png";
$EXTIN="\$EXT";
$EXTOUT="\$EXT";
#preprocess
$DOLOCALCONTRAST=1;
$ROLLING=2;
$BRIGHTNESS=0;
$CONTRAST=0;
$GAMMA=0;
$SATURATION=0;
#superpix params
$SIZE=0;
$METHOD="slic";
$SUPERPIXELS=400;
$ITERATIONS=10;
$COMPACTNESS=40;
$COLORSPACE=0;
$FAIR=0;
$PERTURBSEEDS=0;
#0 = RGB, >0 = Lab
#slic params
#ccs params
#crs params
$CLIQUECOST=.3;
#cw params
#ergc params
#ers parameters
$ERS_LAMBDA=0.5;
$ERS_SIGMA=5;
$ERS_8CONNECTED=0;
#etps params
$ETPS_REGULARIZATIONWEIGHT=1;
$ETPS_LENGTHWEIGHT=1;
$ETPS_SIZEWEIGHT=1;
#fh params
$FH_SIGMA=0;
$FH_THRESHOLD=20;
$FH_MINIMUMSIZE=10;
#refh params
$REFH_SIGMA=0;
$REFH_THRESHOLD=20;
$REFH_MINIMUMSIZE=10;
#lsc params
$LSC_RATIO=0.075;
$LSC_THRESHOLD=4;
#mss params
$MSS_STRUCTURESIZE=7;
$MSS_NOISE=.3;
$MSS_TOLERANCE=7;
#pb params
$PB_SIGMA=20;
$PB_MAXFLOW=0;
#reseeds params
$RESEEDS_BINS=5;
$RESEEDS_NEIGHBORHOOD=1;
$RESEEDS_CONFIDENCE=.1;
$RESEEDS_SPATIALWEIGHT=.25;
#seeds params
$SEEDS_BINS=5;
$SEEDS_PRIOR=1;
$SEEDS_CONFIDENCE=.1;
$SEEDS_MEANS=1;
#vc params
$VC_WEIGHT=5;
$VC_RADIUS=3;
$VC_NEIGHBORINGCLUSTERS=200;
$VC_DIRECTNEIGHBORS=4;
$VC_THRESHOLD=10;
#
$DREAMSMOOTH=0;
$DILATE=0;
$HINTDILATE=10;
$DOCOMPO=1;
$BLENDMODE="multiply";
$BLENDOPACITY=1;
$INVERTSLIC=1;
$CONNEX=4;
$DOPOTRACE=1;
$BLACKLEVEL=.5;
#
$VERBOSE=0;
$CLEAN=1;
$GPU=0;
$CSV=0;
$LOG1=">/var/tmp/$scriptname.log";
$LOG2="2>/var/tmp/$scriptname.log";
#JSON
$CAPACITY=500;
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
print AUTOCONF confstr(DOLOCALCONTRAST);
print AUTOCONF confstr(ROLLING);
print AUTOCONF confstr(BRIGHTNESS);
print AUTOCONF confstr(CONTRAST);
print AUTOCONF confstr(GAMMA);
print AUTOCONF confstr(SATURATION);
print AUTOCONF confstr(METHOD);
print AUTOCONF "#slic/ccs\n";
print AUTOCONF "#superpixels parameters\n";
print AUTOCONF confstr(SIZE);
print AUTOCONF confstr(SUPERPIXELS);
print AUTOCONF confstr(ITERATIONS);
print AUTOCONF confstr(COMPACTNESS);
print AUTOCONF confstr(COLORSPACE);
print AUTOCONF "#0 = RGB, >0 = Lab\n";
print AUTOCONF confstr(FAIR);
print AUTOCONF confstr(PERTURBSEEDS);
print AUTOCONF "#slic parameters\n";
print AUTOCONF "#ccs parameters\n";
print AUTOCONF "#crs parameters\n";
print AUTOCONF confstr(CLIQUECOST);
print AUTOCONF "#cw parameters  !! doesn't build on 18.04\n";
print AUTOCONF "#ergc parameters\n";
print AUTOCONF "#ers parameters\n";
print AUTOCONF confstr(ERS_LAMBDA);
print AUTOCONF confstr(ERS_SIGMA);
print AUTOCONF confstr(ERS_8CONNECTED);
print AUTOCONF "#etps parameters !! doesn't build on 18.04\n";
print AUTOCONF confstr(ETPS_REGULARIZATIONWEIGHT);
print AUTOCONF confstr(ETPS_LENGTHWEIGHT);
print AUTOCONF confstr(ETPS_SIZEWEIGHT);
print AUTOCONF "#fh parameters\n";
print AUTOCONF confstr(FH_SIGMA);
print AUTOCONF confstr(FH_THRESHOLD);
print AUTOCONF confstr(FH_MINIMUMSIZE);
print AUTOCONF "#refh parameters\n";
print AUTOCONF confstr(REFH_SIGMA);
print AUTOCONF confstr(REFH_THRESHOLD);
print AUTOCONF confstr(REFH_MINIMUMSIZE);
print AUTOCONF "#lsc parameters\n";
print AUTOCONF confstr(LSC_RATIO);
print AUTOCONF confstr(LSC_THRESHOLD);
print AUTOCONF "#mss parameters\n";
print AUTOCONF confstr(MSS_NOISE);
print AUTOCONF confstr(MSS_STRUCTURESIZE);
print AUTOCONF confstr(MSS_TOLERANCE);
print AUTOCONF "#pb parameters\n";
print AUTOCONF confstr(PB_SIGMA);
print AUTOCONF confstr(PB_MAXFLOW);
print AUTOCONF "#reseeds parameters\n";
print AUTOCONF confstr(RESEEDS_BINS);
print AUTOCONF confstr(RESEEDS_NEIGHBORHOOD);
print AUTOCONF confstr(RESEEDS_CONFIDENCE);
print AUTOCONF confstr(RESEEDS_SPATIALWEIGHT);
print AUTOCONF "#seeds parameters\n";
print AUTOCONF confstr(SEEDS_BINS);
print AUTOCONF confstr(SEEDS_PRIOR);
print AUTOCONF confstr(SEEDS_CONFIDENCE);
print AUTOCONF confstr(SEEDS_MEANS);
print AUTOCONF "#vc params\n";
print AUTOCONF confstr(VC_WEIGHT);
print AUTOCONF confstr(VC_RADIUS);
print AUTOCONF confstr(VC_NEIGHBORINGCLUSTERS);
print AUTOCONF confstr(VC_DIRECTNEIGHBORS);
print AUTOCONF confstr(VC_THRESHOLD);
print AUTOCONF "#postprocess\n";
print AUTOCONF confstr(DREAMSMOOTH);
print AUTOCONF confstr(DILATE);
print AUTOCONF confstr(HINTDILATE);
print AUTOCONF confstr(DOCOMPO);
print AUTOCONF confstr(BLENDMODE);
print AUTOCONF confstr(BLENDOPACITY);
print AUTOCONF confstr(INVERTSLIC);
print AUTOCONF confstr(CONNEX);
print AUTOCONF confstr(DOPOTRACE);
print AUTOCONF confstr(BLACKLEVEL);
print AUTOCONF confstr(CONNEX);
print AUTOCONF "#\n";
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
  if (@ARGV[$arg] eq "-shot") 
    {
    $SHOT=@ARGV[$arg+1];
    print "shotname : $SHOT\n";
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
  }
  
$userName =  $ENV{'USER'}; 
if ($userName eq "lulu" || $userName eq "dev")	#
  {
  $GMIC="/usr/bin/gmic";
  $SUPERPIX="/shared/foss/superpixel-benchmark/bin";
  $SLIC="/shared/foss/superpixels-revisited/bin/slic_cli";
  $PINKBIN="/shared/foss/Pink/linux/bin";
  $POTRACE="/usr/bin/potrace";
  }
  
if ($userName eq "dev18" || $userName eq "render")	#
  {
  $GMIC="/usr/bin/gmic";
  $SUPERPIX="/shared/foss-18/superpixel-benchmark/bin";
  $SLIC="/shared/foss-18/superpixels-revisited/bin/slic_cli";
  $PINKBIN="/shared/foss-18/Pink/linux/bin";
  $POTRACE="/usr/bin/potrace";
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

$OOUT_C="$OOUTDIR/$OUT\_contour.$ii.$EXTOUT";
$OOUT_M="$OOUTDIR/$OUT\_mean.$ii.$EXTOUT";
$OOUT_R="$OOUTDIR/$OUT\_random.$ii.$EXTOUT";
$OOUT_COMPO="$OOUTDIR/$OUT\_compo.$ii.$EXTOUT";
$OOUT_HINT="$OOUTDIR/$OUT\_hint.$ii.$EXTOUT";

if (-e $OOUT_C && !$FORCE)
   {print BOLD RED "frame $OOUT_C exists ... skipping\n";print RESET;}
else {
  #touch file
  $touchcmd="touch $OOUT_C";
  verbose($touchcmd);
  system $touchcmd;
  #-----------------------------#
  ($s1,$m1,$h1)=localtime(time);
  #-----------------------------#
  #preprocess and workdir
  $WORKDIR="$OOUTDIR/w$ii";
  if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
  #commande
  if ($SIZE || $DOLOCALCONTRAST || $ROLLING || $BRIGHTNESS || $CONTRAST || $GAMMA || $SATURATION)
    {
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
    $cmd="$GMIC $IIN $GMIC4 $GMIC1 $GMIC2 $GMIC3 -o $WORKDIR/$I.png $LOG2";
    verbose($cmd);
    print("--------> preprocess input [size:$SIZE lce:$DOLOCALCONTRAST rolling:$ROLLING bcgs:$BRIGHTNESS/$CONTRAST/$GAMMA/$SATURATION]\n");
    system $cmd;
    $IIN="$WORKDIR/$I.png";
    }
  #
  if ($METHOD eq "slic")
    {
    $cmd="$SUPERPIX/slic_cli $IIN --oc $OOUT_C --om $OOUT_M --or $OOUT_R --superpixels $SUPERPIXELS --compactness $COMPACTNESS --iterations $ITERATIONS --perturb-seeds $PERTURBSEEDS";
    verbose($cmd);
    print("--------> doing slic [super:$SUPERPIXELS compact:$COMPACTNESS iter:$ITERATIONS perturbseeds:$PERTURBSEEDS]\n");
    system $cmd;
    }
  if ($METHOD eq "ccs")
    {
    $cmd="$SUPERPIX/ccs_cli $IIN --oc $OOUT_C --om $OOUT_M --superpixels $SUPERPIXELS  --compactness $COMPACTNESS --iterations $ITERATIONS --color-space $COLORSPACE";
    verbose($cmd);
    print("--------> doing ccs [super:$SUPERPIXELS compact:$COMPACTNESS iter:$ITERATIONS colorspace:$COLORSPACE]\n");
    system $cmd;
    }
  if ($METHOD eq "crs")
    {
    $cmd="$SUPERPIX/crs_cli $IIN --oc $OOUT_C --om $OOUT_M --superpixels $SUPERPIXELS  --compactness $COMPACTNESS --iterations $ITERATIONS --color-space $COLORSPACE --clique-cost $CLIQUECOST";
    if ($FAIR) {$cmd=$cmd." --fair";}
    verbose($cmd);
    print("--------> doing crs [super:$SUPERPIXELS compact:$COMPACTNESS iter:$ITERATIONS colorspace:$COLORSPACE cliquecost:$CLIQUECOST fair:$FAIR]\n");
    system $cmd;
    }
  if ($METHOD eq "cw")
    {
    $cmd="$SUPERPIX/cw_cli $IIN --oc $OOUT_C --om $OOUT_M --superpixels $SUPERPIXELS  --compactness $COMPACTNESS";
    if ($FAIR) {$cmd=$cmd." --fair";}
    verbose($cmd);
    print("--------> doing cw [super:$SUPERPIXELS compact:$COMPACTNESS fair:$FAIR]\n");
    system $cmd;
    }
  if ($METHOD eq "ergc")
    {
    $cmd="$SUPERPIX/ergc_cli $IIN --oc $OOUT_C --om $OOUT_M --superpixels $SUPERPIXELS --compacity $COMPACTNESS --color-space $COLORSPACE --perturb-seeds $PERTURBSEEDS";
    if ($FAIR) {$cmd=$cmd." --fair";}
    verbose($cmd);
    print("--------> doing ergc [super:$SUPERPIXELS compacity:$COMPACTNESS colorspace:$COLORSPACE fair:$FAIR perturbseeds:$PERTURBSEEDS]\n");
    system $cmd;
    }
  if ($METHOD eq "ers")
    {
    $cmd="$SUPERPIX/ers_cli $IIN --oc $OOUT_C --om $OOUT_M --superpixels $SUPERPIXELS --lambda $ERS_LAMBDA --sigma $ERS_SIGMA";
    if ($ERS_8CONNECTED) {$cmd=$cmd." --eight-connected";}
    verbose($cmd);
    print("--------> doing ers [super:$SUPERPIXELS lambda:$ERS_LAMBDA sigma:$ERS_SIGMA 8connex:$ERS_8CONNECTED]\n");
    system $cmd;
    }
  if ($METHOD eq "etps")
    {
    $cmd="$SUPERPIX/etps_cli $IIN --oc $OOUT_C --om $OOUT_M --superpixels $SUPERPIXELS --iterations $ITERATIONS --regularization-weight $ETPS_REGULARIZATIONWEIGHT --length-weight $ETPS_LENGTHWEIGHT --size-weight $ETPS_SIZEWEIGHT";
    verbose($cmd);
    print("--------> doing etps [super:$SUPERPIXELS iters:$ITERATIONS regularizationw:$ETPS_REGULARIZATIONWEIGHT lengthw:$ETPS_LENGTHWEIGHT sizew:$ETPS_SIZEWEIGHT]\n");
    system $cmd;
    }
  if ($METHOD eq "fh")
    {
    $cmd="$SUPERPIX/fh_cli $IIN --oc $OOUT_C --om $OOUT_M --sigma $FH_SIGMA --threshold $FH_THRESHOLD --minimum-size $FH_MINIMUMSIZE";
    verbose($cmd);
    print("--------> doing fh [sigma:$FH_SIGMA threshold:$FH_THRESHOLD minsize:$FH_MINIMUMSIZE]\n");
    system $cmd;
    }
  if ($METHOD eq "lsc")
    {
    $cmd="$SUPERPIX/lsc_cli $IIN --oc $OOUT_C --om $OOUT_M --superpixels $SUPERPIXELS --ratio $LSC_RATIO --iterations $ITERATIONS --threshold $LSC_THRESHOLD --color-space $COLORSPACE";
    if ($FAIR) {$cmd=$cmd." --fair";}
    verbose($cmd);
    print("--------> doing lsc [super:$SUPERPIXELS iters:$ITERATIONS ratio:$LSC_RATIO threshold:$LSC_THRESHOLD colorspace:$COLORSPACE fair:$FAIR]\n");
    system $cmd;
    }
  if ($METHOD eq "mss")
    {
    $cmd="$SUPERPIX/mss_cli $IIN --oc $OOUT_C --om $OOUT_M --superpixels $SUPERPIXELS --iterations $ITERATIONS --structure-size $MSS_STRUCTURESIZE --noise $MSS_NOISE --tolerance $MSS_TOLERANCE";
    verbose($cmd);
    print("--------> doing mss [super:$SUPERPIXELS iters:$ITERATIONS structsize:$MSS_STRUCTURESIZE noise:$MSS_NOISE tolerance:$MSS_TOLERANCE]\n");
    system $cmd;
    }
  if ($METHOD eq "pb")
    {
    $cmd="$SUPERPIX/pb_cli $IIN --oc $OOUT_C --om $OOUT_M --superpixels $SUPERPIXELS --sigma $PB_SIGMA --max-flow $PB_MAXFLOW";
    verbose($cmd);
    print("--------> doing pb [super:$SUPERPIXELS sigma:$PB_SIGMA maxflow:$PB_MAXFLOW]\n");
    system $cmd;
    }
  if ($METHOD eq "preslic")
    {
    $cmd="$SUPERPIX/preslic_cli $IIN --oc $OOUT_C --om $OOUT_M --superpixels $SUPERPIXELS --compactness $COMPACTNESS --iterations $ITERATIONS --color-space $COLORSPACE --perturb-seeds $PERTURBSEEDS";
    verbose($cmd);
    print("--------> doing preslic [super:$SUPERPIXELS compactness:$COMPACTNESS iter:$ITERATIONS colorspace:$COLORSPACE perturbseeds:$PERTURBSEEDS]\n");
    system $cmd;
    }
  if ($METHOD eq "refh")
    {
    $cmd="$SUPERPIX/refh_cli $IIN --oc $OOUT_C --om $OOUT_M --sigma $REFH_SIGMA --threshold $REFH_THRESHOLD --minimum-size $REFH_MINIMUMSIZE";
    verbose($cmd);
    print("--------> doing refh [sigma:$REFH_SIGMA threshold:$REFH_THRESHOLD minsize:$REFH_MINIMUMSIZE]\n");
    system $cmd;
    }
  if ($METHOD eq "reseeds")
    {
    $cmd="$SUPERPIX/reseeds_cli $IIN --oc $OOUT_C --om $OOUT_M --bins $RESEEDS_BINS --neighborhood $RESEEDS_NEIGHBORHOOD --confidence $RESEEDS_CONFIDENCE --iterations $ITERATIONS --spatial-weight $RESEEDS_SPATIALWEIGHT --superpixels $SUPERPIXELS --color-space $COLORSPACE";
    if ($FAIR) {$cmd=$cmd." --fair";}
    verbose($cmd);
    print("--------> doing reseeds [bins:$RESEEDS_BINS neighborhood:$RESEEDS_NEIGHBORHOOD confidence:$RESEEDS_CONFIDENCE iters:$ITERATIONS spatialw:$RESEEDS_SPATIALWEIGHT superpixels:$SUPERPIXELS colorspace:$COLORSPACE fair:$FAIR]\n");
    system $cmd;
    }
  if ($METHOD eq "seeds")
    {
    $cmd="$SUPERPIX/seeds_cli $IIN --oc $OOUT_C --om $OOUT_M --bins $SEEDS_BINS --confidence $SEEDS_CONFIDENCE --iterations $ITERATIONS   --superpixels $SUPERPIXELS --color-space $COLORSPACE --prior $SEEDS_PRIOR --means $SEEDS_MEANS";
    if ($FAIR) {$cmd=$cmd." --fair";}
    verbose($cmd);
    print("--------> doing seeds [bins:$SEEDS_BINS confidence:$SEEDS_CONFIDENCE iters:$ITERATIONS superpixels:$SUPERPIXELS colorspace:$COLORSPACE prior:$SEEDS_PRIORS means:$SEEDS_MEANS fair:$FAIR]\n");
    system $cmd;
    }
  if ($METHOD eq "vc")
    {
    $cmd="$SUPERPIX/vc_cli $IIN --oc $OOUT_C --om $OOUT_M --superpixels $SUPERPIXELS --weight $VC_WEIGHT --radius $VC_RADIUS --neighboring-clusters $VC_NEIGHBORINGCLUSTERS --direct-neighbors $VC_DIRECTNEIGHBORS --threshold $VC_THRESHOLD --color-space $COLORSPACE";
    verbose($cmd);
    print("--------> doing vc [superpixels:$SUPERPIXELS weight:$VC_WEIGHT radius:$VC_RADIUS neighborcluster:$VC_NEIGHBORINGCLUSTERS directneighbor:$VC_DIRECTNEIGHBORS threshold:$VC_THRESHOLD colorspace:$COLORSPACE]\n");
    system $cmd;
    }
  if ($METHOD eq "w")
    {
    $cmd="$SUPERPIX/w_cli $IIN --oc $OOUT_C --om $OOUT_M --superpixels $SUPERPIXELS";
    verbose($cmd);
    print("--------> doing w [superpixels:$SUPERPIXELS]\n");
    system $cmd;
    }
  #copy slic to workdir
  $I=1;
  $cmd="$GMIC -i $OOUT_C -n 0,1 -oneminus -n 0,255 -to_colormode 1 -o $WORKDIR/$I.pgm $LOG2";
  verbose($cmd);
  print("--------> inverting slic\n");
  system $cmd;
  #do barycentre
  $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
  $CONNEX=4;
  $cmd="$PINKBIN/barycentre $PIN $CONNEX $POUT";
  verbose($cmd);
  print("--------> barycentre [connex:$CONNEX]\n");
  system $cmd;
  #make hint
  $cmd="$GMIC $OOUT_M $POUT -dilate_circ[1] $HINTDILATE -split[0] c -append c -o $OOUT_HINT $LOG2";
  #-n[1] 0,1 -oneminus[1] -n[1] 0,255
  verbose($cmd);
  print("--------> hint\n");
  system $cmd;
  #potrace
  if ($DOPOTRACE)
    {
    $I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$GMIC -i $OOUT_C -o $POUT $LOG2";
    verbose($cmd);
    system $cmd;
    $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$POTRACE $PIN -o $POUT -g -k $BLACKLEVEL";
    verbose($cmd);
    print("--------> potrace [blacklevel:$BLACKLEVEL]\n");
    system $cmd;
    #bug potrace
    $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="convert $PIN $POUT";
    verbose($cmd);
    print("--------> potrace bug\n");
    system $cmd;
    $cmd="$GMIC -i $POUT -to_colormode 3 -o $OOUT_C $LOG2";
    system $cmd;
    }
  #
  if ($DREAMSMOOTH)
    {$GMIC1="-fx_dreamsmooth 10,0,1,0.8,0,0.8,0,24,0";} else {$GMIC1="";}
  if ($DILATE)
    {$GMIC2="-dilate $DILATE";} else {$GMIC2="";}
  $cmd="$GMIC -i $OOUT_C $GMIC2 $GMIC1 -o $OOUT_C $LOG2";
  verbose($cmd);
  print("--------> postprocess slic [dilate:$DILATE smooth:$DREAMSMOOTH]\n");
  system $cmd;
  #
  if ($DOCOMPO)
    {
    if ($INVERTSLIC)
        {$GMIC1="-n[1] 0,1 -oneminus[1] -n[1] 0,255";} else {$GMIC1="";}
    $cmd="$GMIC $OOUT_M $OOUT_C  $GMIC1 -blend $BLENDMODE,$BLENDOPACITY -o $OOUT_COMPO $LOG2";
    verbose($cmd);
    print("--------> compo [invertslic:$INVERTSLIC]\n");
    system $cmd;
    }
  #-----------------------------#
  ($s2,$m2,$h2)=localtime(time);
  ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
  #afanasy parsing format
  print BOLD YELLOW "Writing $OOUT_C took $hlat:$mlat:$slat\n";print RESET;
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
  
sub json {
$CMD="SLIC";
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
    $FILES="$OUTDIR/$SHOT/$OUT\_contour.\@####\@.$EXTOUT";
    }
else
    {
    $COMMAND="$CMD.pl -conf $CONF -f @#@ @#@ $SKIP";
    $FILES="$OUTDIR/$OUT\_contour.\@####\@.$EXTOUT";
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
