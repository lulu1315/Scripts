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
$FORCE=0;
$EXTIN="png";
$EXT="png";
$VERBOSE=0;
#preprocess
$SIZE=0;
$SEGMENTSIZE=0;
$DOLOCALCONTRAST=0;
$ROLLING=0;
$BLUR=0;
$BRIGHTNESS=0;
$CONTRAST=0;
$GAMMA=0;
$SATURATION=0;
$USELAB=0;
$BILATERAL=0;
#process params
$DOPREPAREDATA=1;
#
$DOSEGMENTATION=0;
$DORASTERIZATION=0;
$RASTERIZATIONLEVELSTART=20;
$RASTERIZATIONLEVELEND=20;
#
$DOCOUNTLEVELS=0;
#
$DOMASKS=0;
$MASKLEVEL=20;
#
$DOCONCATMASK=0;
$MASKLIST="2,5,6,7,8";
#
$DOMINMAX=0;
$DODEXTR=0;
$DOPOTRACE=0;
$BLACKLEVEL=.5;
$POTRACEBLUR=3;
$POTRACEERODE=0;
#
$DOTRIMAP=0;
$TRIMAPMETHOD=0;
$TRIMAPDILATE=5;
$TRIMAPERODE=5;
#
$DOMATTING=0;
$MATTINGMETHOD=0;
$LINEARIZE=1;
$ROBUSTITER=1;
$DOGUIDEDFILTERING=1;
$GUIDEDRADIUS=5;
$GUIDEDREGULARIZATION=1e-6;
$KNN_NN=20;
$KNN_LAMBDA=100;
$RESIZE=0;
$GLOBALEXPAND=0;
$BAYESIANSIGMA=8;
$BAYESIAN_N=25;
$BAYESIAN_MINN=10;

#segmentation params
$MATTEITER=0;
$FLOWWEIGHT=.2;
$TRESHOLD=.02;
$HIERARCHIES=40;
#
$CONCAT_OUT="concat";
$POTRACE_IN="mask";
$POTRACE_OUT="mask_potrace";
$MINMAX_IN="mask";
$DEXTR_OUT="mask_dextr";
$TRIMAP_IN="mask";
$TRIMAP_OUT="trimap";
$MATTE_OUT="matte";
$GPU=0;
$CLEAN=1;
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
print AUTOCONF confstr(EXTIN);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(IN_USE_SHOT);
print AUTOCONF confstr(OUT_USE_SHOT);
print AUTOCONF confstr(SHOT);
print AUTOCONF confstr(INDIR);
print AUTOCONF confstr(IN);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(OUT);
print AUTOCONF "#originales downsampling\n";
print AUTOCONF confstr(SIZE);
print AUTOCONF "#segmentation downsampling\n";
print AUTOCONF confstr(SEGMENTSIZE);
print AUTOCONF "#preprocess\n";
print AUTOCONF confstr(DOLOCALCONTRAST);
print AUTOCONF confstr(ROLLING);
print AUTOCONF confstr(BRIGHTNESS);
print AUTOCONF confstr(CONTRAST);
print AUTOCONF confstr(GAMMA);
print AUTOCONF confstr(SATURATION);
print AUTOCONF confstr(BILATERAL);
print AUTOCONF "#process\n";
print AUTOCONF confstr(DOPREPAREDATA);
print AUTOCONF confstr(DOSEGMENTATION);
print AUTOCONF "#\n";
print AUTOCONF confstr(DORASTERIZATION);
print AUTOCONF confstr(RASTERIZATIONLEVELSTART);
print AUTOCONF confstr(RASTERIZATIONLEVELEND);
print AUTOCONF "#\n";
print AUTOCONF confstr(DOCOUNTLEVELS);
print AUTOCONF "#\n";
print AUTOCONF confstr(DOMASKS);
print AUTOCONF confstr(DOCONCATMASK);
print AUTOCONF confstr(CONCAT_OUT);
print AUTOCONF confstr(MASKLEVEL);
print AUTOCONF confstr(MASKLIST);
print AUTOCONF "#\n";
print AUTOCONF confstr(DOPOTRACE);
print AUTOCONF confstr(POTRACE_IN);
print AUTOCONF confstr(POTRACE_OUT);
print AUTOCONF confstr(POTRACEBLUR);
print AUTOCONF confstr(POTRACEERODE);
print AUTOCONF confstr(BLACKLEVEL);
print AUTOCONF "#\n";
print AUTOCONF confstr(DOMINMAX);
print AUTOCONF confstr(MINMAX_IN);
print AUTOCONF confstr(DODEXTR);
print AUTOCONF confstr(DEXTR_OUT);
print AUTOCONF "#\n";
print AUTOCONF confstr(DOTRIMAP);
print AUTOCONF confstr(TRIMAPMETHOD);
print AUTOCONF confstr(TRIMAP_IN);
print AUTOCONF confstr(TRIMAP_OUT);
print AUTOCONF confstr(TRIMAPDILATE);
print AUTOCONF confstr(TRIMAPERODE);
print AUTOCONF "#\n";
print AUTOCONF confstr(DOMATTING);
print AUTOCONF confstr(MATTE_OUT);
print AUTOCONF confstr(LINEARIZE);
print AUTOCONF confstr(RESIZE);
print AUTOCONF confstr(MATTINGMETHOD);
print AUTOCONF "#0 : All methods\n";
print AUTOCONF "#1 : Robust Matting (2006)\n";                     #
print AUTOCONF confstr(ROBUSTITER);
print AUTOCONF "#2 : Closed Form Matting (2008)\n";                #
print AUTOCONF "#3 : Global Matting (2011)\n";                     #
print AUTOCONF confstr(GLOBALEXPAND);
print AUTOCONF "#4 : knn Matting (2012) FOIREUX\n";                        #
print AUTOCONF confstr(KNN_NN);
print AUTOCONF confstr(KNN_LAMBDA);
print AUTOCONF "#5 : Bayesian Matting (2001)\n";                   #
print AUTOCONF "#6 : Learning Based Matting (2009)\n";             #
print AUTOCONF "#7 : Alpha Matting (Shared Sampling) (2010)\n";    #
print AUTOCONF "#8 : Mishima Matting (1993) FOIREUX\n";                    #
print AUTOCONF "#Filtering\n";    #
print AUTOCONF confstr(DOGUIDEDFILTERING);
print AUTOCONF confstr(GUIDEDRADIUS);
print AUTOCONF confstr(GUIDEDREGULARIZATION);
print AUTOCONF "#misc\n";
print AUTOCONF confstr(GPU);
print AUTOCONF confstr(CLEAN);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(VERBOSE);
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
      print "-size process xsize\n";
      print "-h hierarchies [40]\n";
      print "-force\n";
      print "-gpu gpu_id [0]\n";
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
    
#auto frames
if ($FSTART eq "auto" || $FEND eq "auto")
    {
    if ($IN_USE_SHOT) {$AUTODIR="$INDIR/$SHOT";} else {$AUTODIR="$INDIR";}
    print ("frames $FSTART $FEND dir $AUTODIR\n");
    opendir DIR, "$AUTODIR";
    @images = grep { /$IN/ && /$EXTIN/ } readdir DIR;
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
    }
    
print ("final seq : $FSTART $FEND\n");
$FFSTART=1;
$FFEND=($FEND-$FSTART+1);
print ("shifted seq : $FFSTART $FFEND\n");

    }
  if (@ARGV[$arg] eq "-f")
    {
    $FSTART=@ARGV[$arg+1];
    $FEND=@ARGV[$arg+2];
    print "seq : $FSTART $FEND\n";
    }
  if (@ARGV[$arg] eq "-ff")
    {
    $FFSTART=@ARGV[$arg+1];
    $FFEND=@ARGV[$arg+2];
    print "shifted seq : $FFSTART $FFEND\n";
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
  if (@ARGV[$arg] eq "-h")
    {
    $HIERARCHIES=@ARGV[$arg+1];
    print "hierarchies : $HIERARCHIES\n";
    }
 if (@ARGV[$arg] eq "-size")
    {
    $SIZE=@ARGV[$arg+1];
    print "process xsize : $SIZE\n";
    }
 if (@ARGV[$arg] eq "-gpu")
    {
    $GPU=@ARGV[$arg+1];
    print "gpu_id : $GPU\n";
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
  }
  
if ($userName eq "dev18")	#
  {
  $GMIC="/usr/bin/gmic";
  #$OFLOW_CLI="/shared/foss-18/hierarchical-graph-based-video-segmentation/build/optical_flow_cli/optical_flow_cli";
  $OFLOW_CLI="/shared/foss-18/hierarchical-graph-based-video-segmentation/build/optical_flow_cli/optical_deepflow_cli";
  $SEGMENT_CLI="/shared/foss-18/hierarchical-graph-based-video-segmentation/build/segment_cli/segment_cli";
  $COUNTLEVELS="/shared/foss-18/DEXTR-PyTorch/extractor/build/count_levels";
  $GENERATEMASK="/shared/foss-18/DEXTR-PyTorch/extractor/build/generate_masks";
  $GENERATEMASKBYID="/shared/foss-18/DEXTR-PyTorch/extractor/build/generate_masks_byid";
  $MINMAX="/shared/foss-18/DEXTR-PyTorch/extractor/build/minmax";
  $DEXTR="python3 /shared/foss-18/DEXTR-PyTorch/demo.py";
  $VIDEOSEGMENT="/shared/foss-18/video_segment/bin/seg_tree_sample/seg_tree_sample";
  $SEGMENTVIEWER="/shared/foss-18/video_segment/bin/segment_viewer/segment_viewer";
  $SEGMENTCONVERT="/shared/foss-18/video_segment/bin/segment_converter/segment_converter";
  $ENV{LD_LIBRARY_PATH} = "/shared/foss-18/opencv-3.4.5_install/lib:$ENV{'LD_LIBRARY_PATH'}";
  $GLOBALMATTING="/shared/foss-18/global-matting/build/globalmatting";
  #$GUIDEDFILTER="/shared/foss-18/global-matting/build/filter"; #foireux gmic marche mieux
  $BINARIZETRIMAP="/shared/foss-18/global-matting/build/binarizetrimap";
  $ROBUSTMATTING="/shared/foss-18/RobustMatting/build/RobustMatting";
  $KNNMATTING="python3 /shared/foss-18/knn-matting/knn_matting.py";
  $BAYESIANMATTING="/shared/foss-18/Bayesian_Matting/build/bayesianmatting";
  $CLOSEDFORM="python3 /shared/foss-18/closed-form-matting/closed_form_matting.py";
  $LEARNINGBASED="python3 /shared/foss-18/learning-based-matting/learning_based_matting.py";
  $MISHIMA="python3 /shared/foss-18/mishima-matting/mishima_matting.py";
  $ALPHAMATTING="/shared/foss-18/AlphaMatting/build/alphamatting";
  $POTRACE="/usr/bin/potrace";
  }
  


#shot directories
if ($IN_USE_SHOT) {$IINDIR="$INDIR/$SHOT";}
else {$IINDIR="$INDIR";}
    
if ($OUT_USE_SHOT) {$OOUTDIR="$OUTDIR/$SHOT";
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    }
else {$OOUTDIR="$OUTDIR";}
    
$DATADIR="$OOUTDIR/originales";
if ($DOPREPAREDATA)
{

if (-e "$DATADIR") {verbose("$DATADIR already exists");}
else {$cmd="mkdir $DATADIR";system $cmd;}

for ($i = $FSTART ;$i <= $FEND;$i++)
    {
    $j=$i-$FSTART+1;
    $ii=sprintf("%04d",$i);
    $jj=sprintf("%04d",$j);
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
    if ($USELAB) 
        {$GMIC5="-rgb2lab";} 
    if ($BILATERAL) 
        {$GMIC6="-bilateral $BILATERAL,$BILATERAL";} 
    else {$GMIC6="";}
    if ($BLUR) 
        {$GMIC7="-b $BLUR";} 
    else {$GMIC7="";}
    if ($EXTIN eq "exr")
        {$GMIC8="-mul 255 -apply_gamma 2.2";} 
    else {$GMIC8="";}
    $cmd="$GMIC -i $IINDIR/$IN.$ii.$EXTIN -to_colormode 3 $GMIC8 $GMIC4 $GMIC1 $GMIC2 $GMIC7 $GMIC3 $GMIC5 $GMIC6 -o $DATADIR/$OUT.$jj.png $LOG2";
    verbose($cmd);
    print BOLD YELLOW "frame : $i ";print RESET;
    print("-> preprocess input [size:$SIZE lce:$DOLOCALCONTRAST rolling:$ROLLING bcgs:$BRIGHTNESS/$CONTRAST/$GAMMA/$SATURATION uselab:$USELAB bilateral:$BILATERAL]\n");
    system $cmd;
    }
}#end preparedata

#$FSTART=1;
#$FEND=($FEND-$FSTART+1);
#print ("shifted seq : $FSTART $FEND\n");

$PBDIR="$OOUTDIR/videosegment";
if ($DOSEGMENTATION)
    {
    if (-e "$PBDIR") {verbose("$PBDIR already exists");}
    else {$cmd="mkdir $PBDIR";system $cmd;}
    if (-e "$PBDIR/$IN.pb" && !$FORCE)
        {print BOLD RED "$PBDIR/$OUT.pb exists ... skipping\n";print RESET;}
    else {
        $cmd="$VIDEOSEGMENT --input_file=$DATADIR/$OUT.\%04d.png --output_file=$PBDIR/$OUT --downscale_min_size=$SEGMENTSIZE --logging --write_to_file";
        #$cmd="$VIDEOSEGMENT --input_file=$DATADIR/$OUT.mov --output_file=$PBDIR/$OUT --downscale_min_size=$SIZE --logging --over_segment --write_to_file";
        #--use_pipeline=0 --chunk_size=240
        verbose($cmd);
        system $cmd;
        $cmd="$SEGMENTVIEWER --input=$PBDIR/$OUT.pb";
        verbose($cmd);
        system $cmd;
        }
    }
    
if ($DORASTERIZATION)
    {
    $SEGDIR="$OOUTDIR/segment";
    if (-e "$SEGDIR") {verbose("$SEGDIR already exists");}
    else {$cmd="mkdir $SEGDIR";system $cmd;}
    $VISDIR="$OOUTDIR/vis";
    if (-e "$VISDIR") {verbose("$VISDIR already exists");}
    else {$cmd="mkdir $VISDIR";system $cmd;}
    
    #$TEXTDIR="$OOUTDIR/text";
    #if (-e "$TEXTDIR") {verbose("$TEXTDIR already exists");}
    #else {$cmd="mkdir $TEXTDIR";system $cmd;}
    #$cmd="$SEGMENTCONVERT --input=$PBDIR/$OUT.pb --output_dir=$TEXTDIR --text_format";
    #verbose($cmd);
    #system $cmd;
    
    for ($j = $RASTERIZATIONLEVELSTART ;$j <= $RASTERIZATIONLEVELEND;$j++)
        {
        $SEGDIRLEV="$SEGDIR/$j";
        if (-e "$SEGDIRLEV") {verbose("$SEGDIRLEV already exists");}
        else {$cmd="mkdir $SEGDIRLEV";system $cmd;}
        $VISDIRLEV="$VISDIR/$j";
        if (-e "$VISDIRLEV") {verbose("$VISDIRLEV already exists");}
        else {$cmd="mkdir $VISDIRLEV";system $cmd;}
        $cmd="$SEGMENTCONVERT --input=$PBDIR/$OUT.pb --output_dir=$SEGDIRLEV --bitmap_ids=$j";
        verbose($cmd);
        system $cmd;
        $cmd="$SEGMENTCONVERT --input=$PBDIR/$OUT.pb --output_dir=$VISDIRLEV --bitmap_color=$j";
        verbose($cmd);
        system $cmd;
        for ($i = $FFSTART ;$i <= $FFEND;$i++)
            {
            $ii=sprintf("%04d",$i);
            $cmd="$GMIC $VISDIRLEV/$ii.png $SEGDIRLEV/$ii.png -split c -remove[2] -remove[2] -remove[2] -append c -o $VISDIRLEV/$ii.png $LOG2";
            print "reformatting image $VISDIRLEV/$ii.png\n";
            verbose($cmd);
            system $cmd;
            }
        }
    }
    
if ($DOCOUNTLEVELS)
    {
    $cmd="$COUNTLEVELS $OOUTDIR/segment $RASTERIZATIONLEVELSTART $RASTERIZATIONLEVELEND $FFSTART $FFEND";
    verbose($cmd);
    system $cmd;
    }

#if ($DOMASKS)
#    {
#    $cmd="$GENERATEMASK $OOUTDIR/segment $FFSTART $FFEND $MASKLEVEL";
#    verbose($cmd);
#    system $cmd;
#    }
            
if ($DOCONCATMASK)
{
    $MASKDIR="$OOUTDIR/masks";
    if (-e "$MASKDIR") {verbose("$MASKDIR already exists");}
    else {$cmd="mkdir $MASKDIR";system $cmd;}
    @maskid=split(/,/,$MASKLIST);
    $masks=$#maskid;
    #generate needed masks
    if ($DOMASKS)
    {
    for ($m = 0 ;$m <= $masks;$m++)
        {
        $genmask=@maskid[$m];
        print ("mask $genmask\n");
        $cmd="$GENERATEMASKBYID $OOUTDIR/segment $FFSTART $FFEND $MASKLEVEL $genmask";
        verbose ($cmd);
        system $cmd;
        }
    }
    for ($i = $FFSTART ;$i <= $FFEND;$i++)
    {
        print ("image $i\n");
        $ii=sprintf("%04d",$i);
        $OOUT="$MASKDIR/$CONCAT_OUT.$ii.png";
        if (-e $OOUT && !$FORCE)
            {print BOLD RED "frame $OOUT exists ... skipping\n";print RESET;}
        else 
        {
        #touch file
        $touchcmd="touch $OOUT";
        verbose($touchcmd);
        system $touchcmd;
        $mm=sprintf("%03d",@maskid[0]);
        if (-e "$OOUTDIR/segment/$MASKLEVEL/mask_$mm.$ii.png")
        {
        $cmd="$GMIC $OOUTDIR/segment/$MASKLEVEL/mask_$mm.$ii.png -o $OOUT $LOG2";
        verbose ($cmd);
        system $cmd;
        }
        for ($m = 1 ;$m <= $masks;$m++)
            {
            $mm=sprintf("%03d",@maskid[$m]);
            #print ("merge mask @maskid[$m-1],@maskid[$m]\n");
            if (-e "$OOUTDIR/segment/$MASKLEVEL/mask_$mm.$ii.png")
            {
            $cmd="$GMIC $OOUT $OOUTDIR/segment/$MASKLEVEL/mask_$mm.$ii.png -add -o $OOUT $LOG2";
            verbose ($cmd);
            system $cmd;
            }
            }
        }
    }
}
    
if ($DOPOTRACE)
    {
    $MASKDIR="$OOUTDIR/masks";
    if (-e "$MASKDIR") {verbose("$MASKDIR already exists");}
    else {$cmd="mkdir $MASKDIR";system $cmd;}
    $WORKDIR="$MASKDIR/tmp";
    if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
        for ($i = $FFSTART ;$i <= $FFEND;$i++)
        {
        $ii=sprintf("%04d",$i);
        $I=1;
        $cmd="$GMIC $OOUTDIR/masks/$POTRACE_IN.$ii.png -erode $POTRACEERODE,0 -b $POTRACEBLUR -o $WORKDIR/$I.pgm";
        verbose($cmd);
        system $cmd;
        $cmd="$GMIC $WORKDIR/$I.pgm -o $OOUTDIR/masks/$POTRACE_OUT\_blur.$ii.png";
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
        $cmd="$GMIC $POUT -to_colormode 3 -o $OOUTDIR/masks/$POTRACE_OUT.$ii.png $LOG2";
        verbose($cmd);
        system $cmd;
        }
    }
    
if ($DOMINMAX)
    {
    $cmd="$MINMAX $OOUTDIR/masks/$MINMAX_IN $FFSTART $FFEND $MASKLEVEL";
    verbose($cmd);
    system $cmd;
    }

if ($DODEXTR)
{
    for ($i = $FFSTART ;$i <= $FFEND;$i++)
    {
        $ii=sprintf("%04d",$i);
        $OOUT="$OOUTDIR/masks/$DEXTR_OUT.$ii.png";
        if (-e $OOUT && !$FORCE)
            {print BOLD RED "frame $OOUT exists ... skipping\n";print RESET;}
        else 
        {
        #touch file
        $touchcmd="touch $OOUT";
        verbose($touchcmd);
        system $touchcmd;
        $cmd="$DEXTR --in $DATADIR/$OUT.$ii.png --minmax $OOUTDIR/masks/$MINMAX_IN\_minmax.$ii.txt --out $OOUTDIR/masks/$DEXTR_OUT.$ii.png --gpu $GPU";
        verbose($cmd);
        system $cmd;
        }
    }
}

if ($DOTRIMAP)
{
    $MATTEDIR="$OOUTDIR/matting";
    if (-e "$MATTEDIR") {verbose("$MATTEDIR already exists");}
    else {$cmd="mkdir $MATTEDIR";system $cmd;}
    for ($i = $FFSTART ;$i <= $FFEND;$i++)
    {
        $ii=sprintf("%04d",$i);
        $OOUT="$MATTEDIR/$TRIMAP_OUT.$ii.png";
        if (-e $OOUT && !$FORCE)
            {print BOLD RED "frame $OOUT exists ... skipping\n";print RESET;}
        else 
        {
        #touch file
        $touchcmd="touch $OOUT";
        verbose($touchcmd);
        system $touchcmd;
        if ($TRIMAPMETHOD == 0)
        {
        $TRIMAPTRESHOLD=127;
        $TRIMAPGUIDEDRADIUS=20;
        $TRIMAPGUIDEDREGULARIZATION=1e-6;
        $TRIMAPGUIDEDREGULARIZATION *= 255 * 255;
        $cmd="$GMIC $OOUTDIR/masks/$TRIMAP_IN.$ii.png $DATADIR/$OUT.$ii.png -to_colormode[1] 1 -guided[0] [1],$TRIMAPGUIDEDRADIUS,$TRIMAPGUIDEDREGULARIZATION -cut 0,255 -remove[1] -ge $TRIMAPTRESHOLD -mul 255 -o $MATTEDIR/$TRIMAP_IN\_guided.$ii.png";
        #$cmd="$GMIC $OOUTDIR/masks/compo.$ii.png $OOUTDIR/masks/compo_dextr.$ii.png -erode[0] $TRIMAPERODE -dilate[1] $TRIMAPDILATE -div 1.99 -add -cut 0,255 -o $MATTEDIR/trimap.$ii.png";
        verbose($cmd);
        print("--------> trimap method 0 [treshold:$TRIMAPTRESHOLD radius:$TRIMAPGUIDEDRADIUS  regularization:$TRIMAPGUIDEDREGULARIZATION]..\n");
        system $cmd;
        $cmd="$GMIC $MATTEDIR/$TRIMAP_IN\_guided.$ii.png --erode_circ[0] $TRIMAPERODE,0 --dilate_circ[0] $TRIMAPDILATE,0 -remove[0] -div 1.99 -add -cut 0,255 -o $MATTEDIR/$TRIMAP_OUT.$ii.png";
        #$cmd="$GMIC $OOUTDIR/masks/compo.$ii.png $OOUTDIR/masks/compo_dextr.$ii.png -erode[0] $TRIMAPERODE -dilate[1] $TRIMAPDILATE -div 1.99 -add -cut 0,255 -o $MATTEDIR/trimap.$ii.png";
        verbose($cmd);
        print("--------> eroding/dilating [erode:$TRIMAPERODE dilate:$TRIMAPDILATE] ..\n");
        system $cmd;
        }
        if ($TRIMAPMETHOD == 1)
        {
        $cmd="$GMIC $MATTEDIR/$TRIMAP_IN.$ii.png --erode_circ[0] $TRIMAPERODE,0 --dilate_circ[0] $TRIMAPDILATE,0 -remove[0] -div 1.99 -add -cut 0,255 -o $MATTEDIR/$TRIMAP_OUT.$ii.png";
        #$cmd="$GMIC $OOUTDIR/masks/compo.$ii.png $OOUTDIR/masks/compo_dextr.$ii.png -erode[0] $TRIMAPERODE -dilate[1] $TRIMAPDILATE -div 1.99 -add -cut 0,255 -o $MATTEDIR/trimap.$ii.png";
        verbose($cmd);
        print("--------> trimap method 1 (eroding/dilating) [erode:$TRIMAPERODE dilate:$TRIMAPDILATE] ..\n");
        system $cmd;
        }
        }
    }
}
  
if ($DOMATTING)
{
    $MATTEDIR="$OOUTDIR/matting";
    if (-e "$MATTEDIR") {verbose("$MATTEDIR already exists");}
    else {$cmd="mkdir $MATTEDIR";system $cmd;}
    $GUIDEDREGULARIZATION *= 255 * 255;
    for ($i = $FFSTART ;$i <= $FFEND;$i++)
    {
        $ii=sprintf("%04d",$i);
        if ($MATTINGMETHOD == 0)
            {$OOUT="$MATTEDIR/$MATTE_OUT\_robust.$ii.png";}
        else
            {$OOUT="$MATTEDIR/$MATTE_OUT\_m$MATTINGMETHOD.$ii.png";}
        if (-e $OOUT && !$FORCE)
            {print BOLD RED "frame $OOUT exists ... skipping\n";print RESET;}
        else 
            {
            #touch file
            $touchcmd="touch $OOUT";
            verbose($touchcmd);
            system $touchcmd;
            #resize
            $WORKDIR="$MATTEDIR/w$ii\_$$";
            if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
            $linear=1/2.2;
            if ($LINEARIZE) {$GMIC1="-apply_gamma $linear";} else {$GMIC1="";}
            if ($RESIZE) {$GMIC2="-resize2dx $RESIZE,5";} else {$GMIC2="";}
            if ($RESIZE) {$GMIC3="-resize2dx $RESIZE,1";} else {$GMIC3="";}
            if ($LINEARIZE || $RESIZE)
                {
                $cmd="$GMIC $DATADIR/$OUT.$ii.png $GMIC1 $GMIC2 -o $WORKDIR/color.$ii.png";
                verbose($cmd);
                system $cmd;
                $cmd="$GMIC $MATTEDIR/$TRIMAP_OUT.$ii.png $GMIC3 -o $WORKDIR/trimap_orig.$ii.png";
                verbose($cmd);
                system $cmd;
                }
            else
                {
                $cmd="cp $DATADIR/$OUT.$ii.png $WORKDIR/color.$ii.png";
                verbose($cmd);
                system $cmd;
                $cmd="cp $MATTEDIR/$TRIMAP_OUT.$ii.png $WORKDIR/trimap_orig.$ii.png";
                verbose($cmd);
                system $cmd;
                }
            #binarizetrimap
            $cmd="$BINARIZETRIMAP $WORKDIR/trimap_orig.$ii.png $WORKDIR/trimap.$ii.png";
            verbose($cmd);
            print("--------> binarize trimap\n");
            system $cmd;
        #go
        if ($MATTINGMETHOD == 1 || $MATTINGMETHOD == 0)
            {
            #-----------------------------#
            ($s1,$m1,$h1)=localtime(time);
            #-----------------------------#
            $CODENAME="robust";
            $OOUT="$MATTEDIR/$MATTE_OUT\_$CODENAME.$ii.png";
            $cmd="$ROBUSTMATTING $WORKDIR/color.$ii.png $WORKDIR/trimap.$ii.png $OOUT $ROBUSTITER";
            verbose($cmd);
            print("--------> robust matting\n");
            system $cmd;
            if ($DOGUIDEDFILTERING)
            {
            $cmd="$GMIC $OOUT $WORKDIR/color.$ii.png -to_colormode[1] 1 -guided[0] [1],$GUIDEDRADIUS,$GUIDEDREGULARIZATION -cut 0,255 -o[0] $MATTEDIR/$MATTE_OUT\_$CODENAME\_filtered.$ii.png";
            verbose($cmd);
            print("--------> filtering ..\n");
            system $cmd;
            }
            #-----------------------------#
            ($s2,$m2,$h2)=localtime(time);
            ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
            #-----------------------------#
            #afanasy parsing format
            print BOLD YELLOW "Writing $OOUT took $hlat:$mlat:$slat\n";print RESET;
            }
        if ($MATTINGMETHOD == 2 || $MATTINGMETHOD == 0)
            {
            #-----------------------------#
            ($s1,$m1,$h1)=localtime(time);
            #-----------------------------#
            $CODENAME="closedform";
            $OOUT="$MATTEDIR/$MATTE_OUT\_$CODENAME.$ii.png";
            $cmd="$CLOSEDFORM $WORKDIR/color.$ii.png -t $WORKDIR/trimap.$ii.png -o $OOUT";
            verbose($cmd);
            print("--------> closed form matting\n");
            system $cmd;
            if ($DOGUIDEDFILTERING)
            {
            #$GUIDEDITERATIONS=1;
            #$cmd="$GUIDEDFILTER $WORKDIR/color.$ii.png $WORKDIR/trimap.$ii.png $OOUT $MATTEDIR/$MATTE_OUT\_m2_filtered.$ii.png";
            $cmd="$GMIC $OOUT $WORKDIR/color.$ii.png -to_colormode[1] 1 -guided[0] [1],$GUIDEDRADIUS,$GUIDEDREGULARIZATION -cut 0,255 -o[0] $MATTEDIR/$MATTE_OUT\_$CODENAME\_filtered.$ii.png";
            #$cmd="$GMIC $OOUT -fx_smooth_guided $GUIDEDRADIUS,$GUIDEDREGULARIZATION,$GUIDEDITERATIONS,0,1,50,50 -o $MATTEDIR/$MATTE_OUT\_m2_filtered.$ii.png";
            verbose($cmd);
            print("--------> filtering ..\n");
            system $cmd;
            }
            #-----------------------------#
            ($s2,$m2,$h2)=localtime(time);
            ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
            #-----------------------------#
            #afanasy parsing format
            print BOLD YELLOW "Writing $OOUT took $hlat:$mlat:$slat\n";print RESET;
            }
        if ($MATTINGMETHOD == 3 || $MATTINGMETHOD == 0)
            {
            #-----------------------------#
            ($s1,$m1,$h1)=localtime(time);
            #-----------------------------#
            $CODENAME="global";
            $OOUT="$MATTEDIR/$MATTE_OUT\_$CODENAME.$ii.png";
            $cmd="$GLOBALMATTING $WORKDIR/color.$ii.png $WORKDIR/trimap.$ii.png $OOUT $GLOBALEXPAND";
            verbose($cmd);
            print("--------> global matting [expand:$GLOBALEXPAND]\n");
            system $cmd;
            if ($DOGUIDEDFILTERING)
            {
            $cmd="$GMIC $OOUT $WORKDIR/color.$ii.png -to_colormode[1] 1 -guided[0] [1],$GUIDEDRADIUS,$GUIDEDREGULARIZATION -cut 0,255 -o[0] $MATTEDIR/$MATTE_OUT\_$CODENAME\_filtered.$ii.png";
            verbose($cmd);
            print("--------> filtering ..\n");
            system $cmd;
            }
            #-----------------------------#
            ($s2,$m2,$h2)=localtime(time);
            ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
            #-----------------------------#
            #afanasy parsing format
            print BOLD YELLOW "Writing $OOUT took $hlat:$mlat:$slat\n";print RESET;
            }
        if ($MATTINGMETHOD == 4)
            {
            #-----------------------------#
            ($s1,$m1,$h1)=localtime(time);
            #-----------------------------#
            $CODENAME="knn";
            $OOUT="$MATTEDIR/$MATTE_OUT\_$CODENAME.$ii.png";
            $cmd="$KNNMATTING $WORKDIR/color.$ii.png $WORKDIR/trimap.$ii.png $OOUT $KNN_LAMBDA $KNN_NN";
            verbose($cmd);
            print("--------> knn matting [lambda:$KNN_LAMBDA nn:$KNN_NN]\n");
            system $cmd;
            if ($DOGUIDEDFILTERING)
            {
            $cmd="$GMIC $OOUT $WORKDIR/color.$ii.png -to_colormode[1] 1 -guided[0] [1],$GUIDEDRADIUS,$GUIDEDREGULARIZATION -cut 0,255 -o[0] $MATTEDIR/$MATTE_OUT\_$CODENAME\_filtered.$ii.png";
            verbose($cmd);
            print("--------> filtering ..\n");
            system $cmd;
            }
            #-----------------------------#
            ($s2,$m2,$h2)=localtime(time);
            ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
            #-----------------------------#
            #afanasy parsing format
            print BOLD YELLOW "Writing $OOUT took $hlat:$mlat:$slat\n";print RESET;
            }
        if ($MATTINGMETHOD == 5 || $MATTINGMETHOD == 0)
            {
            #-----------------------------#
            ($s1,$m1,$h1)=localtime(time);
            #-----------------------------#
            $CODENAME="bayesian";
            $OOUT="$MATTEDIR/$MATTE_OUT\_$CODENAME.$ii.png";
            $cmd="$BAYESIANMATTING -s $WORKDIR/color.$ii.png -t $WORKDIR/trimap.$ii.png -o $OOUT";
            verbose($cmd);
            #print("--------> bayesian matting [sigma:$BAYESIANSIGMA N=$BAYESIAN_N minN=$BAYESIAN_MINN]\n");
            print("--------> bayesian matting\n");
            system $cmd;
            if ($DOGUIDEDFILTERING)
            {
            $cmd="$GMIC $OOUT $WORKDIR/color.$ii.png -to_colormode[1] 1 -guided[0] [1],$GUIDEDRADIUS,$GUIDEDREGULARIZATION -cut 0,255 -o[0] $MATTEDIR/$MATTE_OUT\_$CODENAME\_filtered.$ii.png";
            verbose($cmd);
            print("--------> filtering ..\n");
            system $cmd;
            }
            #-----------------------------#
            ($s2,$m2,$h2)=localtime(time);
            ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
            #-----------------------------#
            #afanasy parsing format
            print BOLD YELLOW "Writing $OOUT took $hlat:$mlat:$slat\n";print RESET;
            }
        if ($MATTINGMETHOD == 6 || $MATTINGMETHOD == 0)
            {
            #-----------------------------#
            ($s1,$m1,$h1)=localtime(time);
            #-----------------------------#
            $CODENAME="learningbased";
            $OOUT="$MATTEDIR/$MATTE_OUT\_$CODENAME.$ii.png";
            $cmd="$LEARNINGBASED $WORKDIR/color.$ii.png $WORKDIR/trimap.$ii.png $OOUT";
            verbose($cmd);
            print("--------> learning based matting\n");
            system $cmd;
            if ($DOGUIDEDFILTERING)
            {
            $cmd="$GMIC $OOUT $WORKDIR/color.$ii.png -to_colormode[1] 1 -guided[0] [1],$GUIDEDRADIUS,$GUIDEDREGULARIZATION -cut 0,255 -o[0] $MATTEDIR/$MATTE_OUT\_$CODENAME\_filtered.$ii.png";
            verbose($cmd);
            print("--------> filtering ..\n");
            system $cmd;
            }
            #-----------------------------#
            ($s2,$m2,$h2)=localtime(time);
            ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
            #-----------------------------#
            #afanasy parsing format
            print BOLD YELLOW "Writing $OOUT took $hlat:$mlat:$slat\n";print RESET;
            }
        if ($MATTINGMETHOD == 8)
            {
            #-----------------------------#
            ($s1,$m1,$h1)=localtime(time);
            #-----------------------------#
            $CODENAME="mishima";
            $OOUT="$MATTEDIR/$MATTE_OUT\_$CODENAME.$ii.png";
            $cmd="$MISHIMA $WORKDIR/color.$ii.png $WORKDIR/trimap.$ii.png $OOUT";
            verbose($cmd);
            print("--------> mishima matting\n");
            system $cmd;
            if ($DOGUIDEDFILTERING)
            {
            $cmd="$GMIC $OOUT $WORKDIR/color.$ii.png -to_colormode[1] 1 -guided[0] [1],$GUIDEDRADIUS,$GUIDEDREGULARIZATION -cut 0,255 -o[0] $MATTEDIR/$MATTE_OUT\_$CODENAME\_filtered.$ii.png";
            verbose($cmd);
            print("--------> filtering ..\n");
            system $cmd;
            }
            #-----------------------------#
            ($s2,$m2,$h2)=localtime(time);
            ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
            #-----------------------------#
            #afanasy parsing format
            print BOLD YELLOW "Writing $OOUT took $hlat:$mlat:$slat\n";print RESET;
            }
        if ($MATTINGMETHOD == 7 || $MATTINGMETHOD == 0)
            {
            #-----------------------------#
            ($s1,$m1,$h1)=localtime(time);
            #-----------------------------#
            $CODENAME="alphamatting";
            $OOUT="$MATTEDIR/$MATTE_OUT\_$CODENAME.$ii.png";
            $cmd="$ALPHAMATTING $WORKDIR/color.$ii.png $WORKDIR/trimap.$ii.png $OOUT";
            verbose($cmd);
            print("--------> alpha matting (Shared Sampling)\n");
            system $cmd;
            if ($DOGUIDEDFILTERING)
            {
            $cmd="$GMIC $OOUT $WORKDIR/color.$ii.png -to_colormode[1] 1 -guided[0] [1],$GUIDEDRADIUS,$GUIDEDREGULARIZATION -cut 0,255 -o[0] $MATTEDIR/$MATTE_OUT\_$CODENAME\_filtered.$ii.png";
            verbose($cmd);
            print("--------> filtering ..\n");
            system $cmd;
            }
            #-----------------------------#
            ($s2,$m2,$h2)=localtime(time);
            ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
            #-----------------------------#
            #afanasy parsing format
            print BOLD YELLOW "Writing $OOUT took $hlat:$mlat:$slat\n";print RESET;
            }
        
        if ($CLEAN)
            {
            $cleancmd="rm -r $WORKDIR";
            verbose($cleancmd);
            system $cleancmd;
            }
        }
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
