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
$DOLOCALCONTRAST=0;
$ROLLING=0;
$BLUR=0;
$BRIGHTNESS=0;
$CONTRAST=0;
$GAMMA=0;
$SATURATION=0;
#process params
$DOPREPAREDATA=1;
$DOPNG=1;
$DOOPTICALFLOW=1;
$USEOPENCV=1;
#
$DOMOSEG=1;
$MOSEGMETHOD=2015;
#
$MOSEGSAMPLING=8;
$MOSEG2010AFFINEMERGE=1;
$MOSEG2015PRIOR=.6;
$MOSEG2013REGWEIGHT=60;
$ORGANIZEDATA=1;
$DOLABELS2PLY=0;
#
$DOSEGMENTATION=0;
$DORASTERIZATION=0;
$RASTER="0,10,20";
$DOTRACKS2VIDEOSEG=0;
$DOTRACKS2RGB=0;
$DOTRACKS2PLY=0;
#
$DODENSE=0;
$USEGPU=1;
$DENSEREGWEIGHT=.3;
$USEHIERARCHY=0;
#
$FORCE=0;
#log
$LOG1=" > /var/tmp/$scriptname.log";
$LOG2=" 2> /var/tmp/$scriptname.log";

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
print AUTOCONF "#preprocess\n";
print AUTOCONF confstr(DOLOCALCONTRAST);
print AUTOCONF confstr(ROLLING);
print AUTOCONF confstr(BRIGHTNESS);
print AUTOCONF confstr(CONTRAST);
print AUTOCONF confstr(GAMMA);
print AUTOCONF confstr(SATURATION);
print AUTOCONF "#process\n";
print AUTOCONF confstr(DOPREPAREDATA);
print AUTOCONF confstr(DOPNG);
print AUTOCONF "#opticalflow\n";
print AUTOCONF confstr(DOOPTICALFLOW);
print AUTOCONF confstr(USEOPENCV);
print AUTOCONF "#moseg\n";
print AUTOCONF confstr(DOMOSEG);
print AUTOCONF confstr(MOSEGMETHOD);
print AUTOCONF "#2010 : BroxMalik\n";
print AUTOCONF "#2012 : Spectral Clustering\n";
print AUTOCONF "#2013 : BroxMalik\n";
print AUTOCONF "#2015 : multicut\n";
print AUTOCONF confstr(MOSEGSAMPLING);
print AUTOCONF confstr(MOSEG2010AFFINEMERGE);
print AUTOCONF confstr(MOSEG2015PRIOR);
print AUTOCONF confstr(MOSEG2013REGWEIGHT);
print AUTOCONF "#videosegmentation\n";
print AUTOCONF confstr(DOSEGMENTATION);
print AUTOCONF confstr(DORASTERIZATION);
print AUTOCONF confstr(RASTER);
print AUTOCONF confstr(DOLABELS2PLY);
print AUTOCONF "#tracks treatment\n";
print AUTOCONF confstr(DOTRACKS2VIDEOSEG);
print AUTOCONF confstr(DOTRACKS2RGB);
print AUTOCONF confstr(DOTRACKS2PLY);
print AUTOCONF "#densification\n";
print AUTOCONF confstr(DODENSE);
print AUTOCONF confstr(USEGPU);
print AUTOCONF confstr(USEHIERARCHY);
print AUTOCONF confstr(DENSEREGWEIGHT);
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
    print "verbose ...\n";
    }
  }
  
if ($userName eq "dev18")	#
  {
  $GMIC="/usr/bin/gmic";
  $DEEPMATCH="/shared/foss-18/DeepFlow/deepmatching";
  $DEEPFLOW2="/shared/foss-18/DeepFlow/deepflow2";
  $DEEPFLOW_OPENCV="/shared/foss-18/FlowCode/build/deepflow_opencv";
  $MOSEG2010="/shared/foss-18/SegmentationOfMovingObjects/moseg_2010/motionsegBM";  #BroxMalik
  $MOSEG2012="/shared/foss-18/SegmentationOfMovingObjects/moseg_2012/motionsegOB";  #OchsBrok -> Spectral
  $MOSEG2013="/shared/foss-18/SegmentationOfMovingObjects/moseg_2013/MoSeg";
  $MOSEG2015="/shared/foss-18/SegmentationOfMovingObjects/moseg_2015/motionseg_release";
  $DENSE2012="/shared/foss-18/SegmentationOfMovingObjects/SparseToDenseLabeling_2012/dens100"; #hierarchical segmentation
  $DENSE2013="/shared/foss-18/SegmentationOfMovingObjects/moseg_2013/dens100gpu";   #GPU mais limites memoires
  $UCMBIN="/shared/foss-18/opencv-code/ucm/build/ucm";
  $TRACKS2RGB="/shared/foss-18/opencv-code/tracks2rgb/build/tracks2rgb";
  $TRACKS2PLY="/shared/foss-18/opencv-code/tracks2ply/build/tracks2ply";
  $TRACKS2VIDEOSEG="/shared/foss-18/opencv-code/tracks2videoseg/build/tracks2videoseg";
  $LABELS2PLY="/shared/foss-18/opencv-code/labels2ply/build/labels2ply";
  $VIDEOSEGMENT="/shared/foss-18/video_segment/bin/seg_tree_sample/seg_tree_sample";
  $SEGMENTVIEWER="/shared/foss-18/video_segment/bin/segment_viewer/segment_viewer";
  $SEGMENTCONVERT="/shared/foss-18/video_segment/bin/segment_converter/segment_converter";
  $ENV{LD_LIBRARY_PATH} = "/shared/foss-18/SegmentationOfMovingObjects/moseg_2013:$ENV{'LD_LIBRARY_PATH'}";
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

print("-> writing originales.bmf\n");
open (BMF,">","$DATADIR/originales.bmf");
print BMF "$FFEND 1\n";

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
        {$GMIC3="-fx_adjust_colors $BRIGHTNESS,$CONTRAST,$GAMMA,0,$SATURATION,0,255";} 
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
    $cmd="$GMIC -i $IINDIR/$IN.$ii.$EXTIN -to_colormode 3 $GMIC8 $GMIC1 $GMIC3 $GMIC4 $GMIC2 $GMIC7 $GMIC5 $GMIC6 -o $DATADIR/$OUT.$jj.ppm";
    verbose($cmd);
    print BOLD YELLOW "frame : $i ";print RESET;
    print("-> preprocess input [size:$SIZE lce:$DOLOCALCONTRAST rolling:$ROLLING bcgs:$BRIGHTNESS/$CONTRAST/$GAMMA/$SATURATION bilateral:$BILATERAL]\n");
    system $cmd;
    if ($DOPNG)
    {
    $cmd="$GMIC -i $DATADIR/$OUT.$jj.ppm -o $DATADIR/$OUT.$jj.png";
    verbose($cmd);
    print("-> copy ppm to png\n");
    system $cmd;
    }
    print BMF "$OUT.$jj.ppm\n";
    }
}#end preparedata
close BMF;

$FLOWDIR="$OOUTDIR/opticalflow";
if ($DOOPTICALFLOW)
    {
    if (-e "$FLOWDIR") {verbose("$FLOWDIR already exists");}
    else {$cmd="mkdir $FLOWDIR";system $cmd;}
    for ($i = $FFSTART ;$i < $FFEND;$i++)
        {
        $ii=sprintf("%04d",$i);
        $j=$i+1;
        $jj=sprintf("%04d",$j);
        $k=$i-1;
        $kk=sprintf("%03d",$k);
        print("-> opticalflow : image $ii\n");
        #
        $WFILE1="$DATADIR/$OUT.$ii.ppm";
        $WFILE2="$DATADIR/$OUT.$jj.ppm";
        #
        if ($USEOPENCV) 
            {
            $cmd="$DEEPFLOW_OPENCV -g $WFILE1 $WFILE2 $FLOWDIR/ForwardFlow$kk.flo";
            }
            else
            {
            $cmd="$DEEPMATCH $WFILE1 $WFILE2 -nt 0 | $DEEPFLOW2 $WFILE1 $WFILE2 $FLOWDIR/ForwardFlow$kk.flo -match -sintel $LOG1";
            }
        verbose($cmd);
        system $cmd;
        #
        if ($USEOPENCV) 
            {
            $cmd="$DEEPFLOW_OPENCV -g $WFILE2 $WFILE1 $FLOWDIR/BackwardFlow$kk.flo";
            }
            else
            {
            $cmd="$DEEPMATCH $WFILE2 $WFILE1 -nt 0 | $DEEPFLOW2 $WFILE2 $WFILE1 $FLOWDIR/BackwardFlow$kk.flo -match -sintel $LOG1";
            }
        verbose($cmd);
        system $cmd;
        }
    }

if ($DOMOSEG)
    {
    if (($MOSEGMETHOD == 2010) || ($MOSEGMETHOD == 0))
        {
        $RESULTDIR="$DATADIR/BroxMalikResults";
        $RRESULTDIR="$OOUTDIR/moseg_2010_s$MOSEGSAMPLING\_am$MOSEG2010AFFINEMERGE";
        #copy flow files
        $cmd="mkdir $RESULTDIR";
        verbose($cmd);
        system $cmd;
        $cmd="cp $OOUTDIR/opticalflow/* $RESULTDIR";
        verbose($cmd);
        system $cmd;
        #process moseg
        $cmd="$MOSEG2010 $DATADIR/originales.bmf 0 $FFEND $MOSEGSAMPLING -1 $MOSEG2010AFFINEMERGE";
        verbose($cmd);
        print("-> moseg2010 [sampling:$MOSEGSAMPLING affinemerge:$MOSEG2010AFFINEMERGE]\n");
        system $cmd;
        #reorganize
        $cmd="mv $RESULTDIR $RRESULTDIR";
        verbose($cmd);
        system $cmd;
        $DATFILE="$RRESULTDIR/Tracks$FFEND.dat";
        for ($i = $FFSTART ;$i <= $FFEND;$i++)
            {
            $ii=sprintf("%04d",$i);
            $j=$i-1;
            $cmd="$TRACKS2RGB $DATFILE $j $DATADIR/$OUT.$ii.ppm $RRESULTDIR/$OUT\_segments.$ii.ppm 0";
            verbose($cmd);
            system $cmd;
            }
        }
    if (($MOSEGMETHOD == 2012) || ($MOSEGMETHOD == 0))
        {
        $RESULTDIR="$DATADIR/OchsBroxResults";
        $RRESULTDIR="$OOUTDIR/moseg_2012_s$MOSEGSAMPLING";
        #copy flow files
        $cmd="mkdir $RESULTDIR";
        verbose($cmd);
        system $cmd;
        $cmd="cp $OOUTDIR/opticalflow/* $RESULTDIR";
        verbose($cmd);
        system $cmd;
        #process moseg
        #./motionsegOB bmfFile startFrame numberOfFrames sampling
        $cmd="$MOSEG2012 $DATADIR/originales.bmf 0 $FFEND $MOSEGSAMPLING";
        verbose($cmd);
        print("-> moseg2012 [sampling:$MOSEGSAMPLING]\n");
        system $cmd;
        #reorganize
        $cmd="mv $RESULTDIR $RRESULTDIR";
        verbose($cmd);
        system $cmd;
        $DATFILE="$RRESULTDIR/Tracks$FFEND.dat";
        for ($i = $FFSTART ;$i <= $FFEND;$i++)
            {
            $ii=sprintf("%04d",$i);
            $j=$i-1;
            $cmd="$TRACKS2RGB $DATFILE $j $DATADIR/$OUT.$ii.ppm $RRESULTDIR/$OUT\_segments.$ii.ppm 0";
            verbose($cmd);
            system $cmd;
            }
        }
    if (($MOSEGMETHOD == 2013) || ($MOSEGMETHOD == 0))
        {
        #link flow files
        if (!-e "$DATADIR/FlowFiles")
        {$cmd="ln -s $FLOWDIR $DATADIR/FlowFiles";verbose($cmd);system $cmd;}
        #
        print("-> moseg2013 : writing config file\n");
        open (CFG,">","$DATADIR/$OUT.cfg");
        print CFG "s dataDir $OOUTDIR\n";
        print CFG "s resultDir $OOUTDIR\n";
        print CFG "s flowDirIn FlowFiles\n";
        print CFG "s trackingDirOut Tracking\n";
        print CFG "i show_tracking 1\n";
        print CFG "s sparseSegmentationDirOut SparseSegmentation\n";
        close CFG;
        #process moseg
        $cmd="$MOSEG2013 $DATADIR/$OUT.cfg originales 0 $FFEND $MOSEGSAMPLING $MOSEG2013REGWEIGHT";
        verbose($cmd);
        print("-> moseg2013 [sampling:$MOSEGSAMPLING regWeightSegmentation:$MOSEG2013REGWEIGHT]\n");
        system $cmd;
        #reorganize
        $stupid = sprintf("%010.2f",$MOSEG2013REGWEIGHT);
        $RESULTDIR="$OOUTDIR/OchsBroxMalik$MOSEGSAMPLING\_all_$stupid";
        $RRESULTDIR="$OOUTDIR/moseg_2013_s$MOSEGSAMPLING\_w$MOSEG2013REGWEIGHT";
        $cmd="mv $RESULTDIR/originales $RRESULTDIR";
        verbose($cmd);
        system $cmd;
        $cmd="rm -rf $RESULTDIR";
        verbose($cmd);
        system $cmd;
        $cmd="mv $RRESULTDIR/SparseSegmentation/* $RRESULTDIR;rm -r $RRESULTDIR/SparseSegmentation";
        verbose($cmd);
        system $cmd;
        $cmd="mv $RRESULTDIR/Tracking/* $RRESULTDIR;rm -r $RRESULTDIR/Tracking";
        verbose($cmd);
        system $cmd;
        $DATFILE="$RRESULTDIR/Tracks$FFEND.dat";
        for ($i = $FFSTART ;$i <= $FFEND;$i++)
            {
            $ii=sprintf("%04d",$i);
            $j=$i-1;
            $cmd="$TRACKS2RGB $DATFILE $j $DATADIR/$OUT.$ii.ppm $RRESULTDIR/$OUT\_segments.$ii.ppm 0";
            verbose($cmd);
            system $cmd;
            }
        }
        
if (($MOSEGMETHOD == 2015) || ($MOSEGMETHOD == 0))
        {
        #link flow files
        $cmd="mkdir $DATADIR/MulticutResults";
        verbose($cmd);
        system $cmd;
        if (!-e "$DATADIR/MulticutResults/ldof")
            {$cmd="ln -s $FLOWDIR $DATADIR/MulticutResults/ldof";verbose($cmd);system $cmd;}
        #process moseg
        $cmd="$MOSEG2015 $DATADIR/originales.bmf 0 $FFEND $MOSEGSAMPLING $MOSEG2015PRIOR";
        verbose($cmd);
        print("-> moseg2015 [sampling:$MOSEGSAMPLING prior:$MOSEG2015PRIOR]\n");
        system $cmd;
        #reorganize
        $stupid = sprintf("%.6f",$MOSEG2015PRIOR);
        $RESULTDIR="$DATADIR/MulticutResults";
        $RRESULTDIR="$OOUTDIR/moseg_2015_s$MOSEGSAMPLING\_p$MOSEG2015PRIOR";
        $cmd="mv $RESULTDIR/ldof$stupid$MOSEGSAMPLING $RRESULTDIR;rm -r $RESULTDIR";
        verbose($cmd);
        system $cmd;
        $DATFILE="$RRESULTDIR/Tracks$FFEND.dat";
        for ($i = $FFSTART ;$i <= $FFEND;$i++)
            {
            $ii=sprintf("%04d",$i);
            $j=$i-1;
            $cmd="$TRACKS2RGB $DATFILE $j $DATADIR/$OUT.$ii.ppm $RRESULTDIR/$OUT\_segments.$ii.ppm 0";
            verbose($cmd);
            system $cmd;
            }
        }
    }
    
$PBDIR="$OOUTDIR/videosegment";
$SEGDIR="$PBDIR/segment";
$VISDIR="$PBDIR/vis";

if ($DOSEGMENTATION)
    {
    if (-e "$PBDIR") {verbose("$PBDIR already exists");}
    else {$cmd="mkdir $PBDIR";system $cmd;}
    if (-e "$PBDIR/$OUT.pb" && !$FORCE)
        {print BOLD RED "$PBDIR/$OUT.pb exists ... skipping\n";print RESET;}
    else {
        $cmd="$VIDEOSEGMENT --input_file=$DATADIR/$OUT.\%04d.ppm --output_file=$PBDIR/$OUT --logging --write_to_file";
        #$cmd="$VIDEOSEGMENT --input_file=$DATADIR/$OUT.mov --output_file=$PBDIR/$OUT --downscale_min_size=$SIZE --logging --over_segment --write_to_file";
        #--use_pipeline=0 --chunk_size=240
        verbose($cmd);
        system $cmd;
        #preview
        $cmd="$SEGMENTVIEWER --input=$PBDIR/$OUT.pb";
        verbose($cmd);
        system $cmd;
        }
    }
    
if ($MOSEGMETHOD == 2010) {$RESULTDIR="$OOUTDIR/moseg_2010_s$MOSEGSAMPLING";}
if ($MOSEGMETHOD == 2012) {$RESULTDIR="$OOUTDIR/moseg_2012_s$MOSEGSAMPLING";}
if ($MOSEGMETHOD == 2013) {$RESULTDIR="$OOUTDIR/moseg_2013_s$MOSEGSAMPLING\_w$MOSEG2013REGWEIGHT";}
if ($MOSEGMETHOD == 2015) {$RESULTDIR="$OOUTDIR/moseg_2015_s$MOSEGSAMPLING\_p$MOSEG2015PRIOR";}
#par defaut
if ($MOSEGMETHOD == 0) {$RESULTDIR="$OOUTDIR/moseg_2015_s$MOSEGSAMPLING\_p$MOSEG2015PRIOR";}
$DATFILE="$RESULTDIR/Tracks$FFEND.dat";

if ($DOTRACKS2PLY)
    {
    $cmd="$TRACKS2PLY $DATFILE $RESULTDIR/$OUT";
    verbose($cmd);
    system $cmd;
    }
    
if ($DORASTERIZATION)
    {
    if (-e "$PBDIR") {verbose("$PBDIR already exists");}
    else {$cmd="mkdir $PBDIR";system $cmd;}
    if (-e "$VISDIR") {verbose("$VISDIR already exists");}
    else {$cmd="mkdir $VISDIR";system $cmd;}
    if (-e "$SEGDIR") {verbose("$SEGDIR already exists");}
    else {$cmd="mkdir $SEGDIR";system $cmd;}
    @raster=split(/,/,$RASTER);
    $nraster=$#raster;
    #print "raster levels : $nraster\n";
    for ($j=0;$j <= $nraster;$j++)
        {
        $lev=@raster[$j];
        $VISDIRLEV="$VISDIR/$lev";
        if (-e "$VISDIRLEV") {verbose("$VISDIRLEV already exists");}
        else {$cmd="mkdir $VISDIRLEV";system $cmd;}
        $SEGDIRLEV="$SEGDIR/$lev";
        if (-e "$SEGDIRLEV") {verbose("$SEGDIRLEV already exists");}
        else {$cmd="mkdir $SEGDIRLEV";system $cmd;}
        $cmd="$SEGMENTCONVERT --input=$PBDIR/$OUT.pb --output_dir=$VISDIRLEV --bitmap_color=$lev";
        verbose($cmd);
        system $cmd;
        $cmd="$SEGMENTCONVERT --input=$PBDIR/$OUT.pb --output_dir=$SEGDIRLEV --bitmap_ids=$lev";
        verbose($cmd);
        system $cmd;
        }
    }
    
if ($DOTRACKS2VIDEOSEG)
    {
    @raster=split(/,/,$RASTER);
    $nraster=$#raster;
    #print "raster levels : $nraster\n";
    for ($j=0;$j <= $nraster;$j++)
        {
        $lev=@raster[$j];
        $SEGDIRLEV="$SEGDIR/$lev";
        $DATFILEVIDEOSEG="$RESULTDIR/Tracks$FFEND\_videoseg$lev.dat";
        $cmd="$TRACKS2VIDEOSEG $DATFILE $DATFILEVIDEOSEG $SEGDIRLEV";
        verbose($cmd);
        system $cmd;
        if ($DOTRACKS2RGB)
            {
            for ($i = $FFSTART ;$i <= $FFEND;$i++)
                {
                $ii=sprintf("%04d",$i);
                $j=$i-1;
                $cmd="$TRACKS2RGB $DATFILEVIDEOSEG $j $DATADIR/$OUT.$ii.ppm $RESULTDIR/$OUT\_videoseg$lev.$ii.ppm 2";
                verbose($cmd);
                system $cmd;
                }
            }
        if ($DOTRACKS2PLY)
            {
            $cmd="$TRACKS2PLY $DATFILEVIDEOSEG $RESULTDIR/$OUT\_videoseg$lev";
            verbose($cmd);
            system $cmd;
            }
        }
    }
    
if ($DOLABELS2PLY)
    {
    @raster=split(/,/,$RASTER);
    $nraster=$#raster;
    #print "raster levels : $nraster\n";
    for ($j=0;$j <= $nraster;$j++)
        {
        $lev=@raster[$j];
        $SEGDIRLEV="$SEGDIR/$lev";
        for ($i = $FFSTART ;$i <= $FFEND;$i++)
            {
            $ii=sprintf("%04d",$i);
            $OOUT="$SEGDIRLEV/$ii.ply";
            if (-e $OOUT && !$FORCE)
                {print BOLD RED "$OOUT exists ... skipping\n";print RESET;}
            else 
                {
                #touch file
                $touchcmd="touch $OOUT";
                verbose($touchcmd);
                system $touchcmd;
                $cmd="$LABELS2PLY $SEGDIRLEV/$ii.png $SEGDIRLEV/$ii.ply";
                verbose($cmd);
                system $cmd;
                }
            }
        }
    }
    
if ($DODENSE)
    {
    if ($MOSEGMETHOD == 2010) {$RESULTDIR="$OOUTDIR/moseg_2010_s$MOSEGSAMPLING";}
    if ($MOSEGMETHOD == 2012) {$RESULTDIR="$OOUTDIR/moseg_2012_s$MOSEGSAMPLING";}
    if ($MOSEGMETHOD == 2013) {$RESULTDIR="$OOUTDIR/moseg_2013_s$MOSEGSAMPLING\_w$MOSEG2013REGWEIGHT";}
    if ($MOSEGMETHOD == 2015) {$RESULTDIR="$OOUTDIR/moseg_2015_s$MOSEGSAMPLING\_p$MOSEG2015PRIOR";}
    #par defaut
    if ($MOSEGMETHOD == 0) {$RESULTDIR="$OOUTDIR/moseg_2015_s$MOSEGSAMPLING\_p$MOSEG2015PRIOR";}
    #
    $DATFILE="$RESULTDIR/Tracks$FFEND.dat";
    
    if ($USEGPU)
    {
    #print("-> resultdir : $RESULTDIR\n");
    print("-> datfile : $DATFILE\n");
    print("-> densify : writing config file\n");
    open (DENSECFG,">","$DATADIR/$OUT\_dense.cfg");
    print DENSECFG "s dataDir -\n";
    print DENSECFG "s tracksDir -\n";
    print DENSECFG "s resultDir -\n";
    print DENSECFG "f lambda 200.0\n";
    print DENSECFG "i maxiter 2000\n";
    close DENSECFG;
    for ($i = $FFSTART ;$i <= $FFEND;$i++)
        {
        $ii=sprintf("%04d",$i);
        $j=$i-1;
        $OOUT="$RESULTDIR/$OUT\_dense_gpu.$ii.ppm";
        if (-e $OOUT && !$FORCE)
            {print BOLD RED "frame $OOUT exists ... skipping\n";print RESET;}
        else {
            #touch file
            $touchcmd="touch $OOUT";
            verbose($touchcmd);
            system $touchcmd;
            print("-> densify : image $ii\n");
            $cmd="$DENSE2013 $DATADIR/$OUT\_dense.cfg $DATADIR/$OUT.$ii.ppm $DATFILE $j $RESULTDIR";
            verbose($cmd);
            system $cmd;
            $cmd="mv $RESULTDIR/$OUT.$ii\_dense.ppm $RESULTDIR/$OUT\_dense_gpu.$ii.ppm";
            verbose($cmd);
            print("-> ... renaming\n");
            system $cmd;
            $cmd="mv $RESULTDIR/$OUT.$ii\_overlay.ppm $RESULTDIR/$OUT\_overlay_gpu.$ii.ppm";
            verbose($cmd);
            print("-> ... renaming\n");
            system $cmd;
            }
        }
    }
    else
    {
    $SEGMENTDIR="$RESULTDIR/tmp";
    if (-e "$SEGMENTDIR") {verbose("$SEGMENTDIR already exists");}
    else {$cmd="mkdir $SEGMENTDIR";system $cmd;}
        for ($i = $FFSTART ;$i <= $FFEND;$i++)
        {
        $ii=sprintf("%04d",$i);
        if ($USEHIERARCHY)
            {
            @raster=split(/,/,$RASTER);
            $nraster=$#raster;
            $nnraster = $nraster+1;
            $OOUT="$RESULTDIR/$OUT\_dense_h$nnraster\_rw$DENSEREGWEIGHT.$ii.ppm";
            }
        else
            {
            $OOUT="$RESULTDIR/$OUT\_dense_rw$DENSEREGWEIGHT.$ii.ppm";
            }
        if (-e $OOUT && !$FORCE)
            {print BOLD RED "frame $OOUT exists ... skipping\n";print RESET;}
        else {
            #touch file
            $touchcmd="touch $OOUT";
            verbose($touchcmd);
            system $touchcmd;
            #
            $cmd="cp $DATADIR/$OUT.$ii.ppm $SEGMENTDIR";
            verbose($cmd);
            system $cmd;
            #
            #$cmd="cp $RESULTDIR/Segments$jj.ppm $SEGMENTDIR";
            $cmd="cp $RESULTDIR/$OUT\_segments.$ii.ppm $SEGMENTDIR";
            verbose($cmd);
            system $cmd;
            #
            if ($USEHIERARCHY)
                {
                #@raster=split(/,/,$RASTER);
                #$nraster=$#raster;
                #print "raster levels : $nraster\n";
                for ($j=0;$j <= $nraster;$j++)
                    {
                    $VISDIRLEV="$PBDIR/$j";
                    $cmd="gmic $VISDIRLEV/$ii.png -o $SEGMENTDIR/$OUT.$ii\_seg$j.ppm";
                    verbose($cmd);
                    system $cmd;
                    }
                #$nnraster = $nraster+1;
                $cmd="$DENSE2012 $SEGMENTDIR/$OUT.$ii.ppm $nnraster $OUT\_segments.$ii.ppm 0 $DENSEREGWEIGHT";
                verbose($cmd);
                system $cmd;
                #
                $cmd="mv $SEGMENTDIR/OchsBroxResults/$OUT.$ii\_dense.ppm $RESULTDIR/$OUT\_dense_h$nnraster\_rw$DENSEREGWEIGHT.$ii.ppm";
                verbose($cmd);
                system $cmd;
                #
                $cmd="mv $SEGMENTDIR/OchsBroxResults/$OUT.$ii\_dense_soft.ppm $RESULTDIR/$OUT\_dense_soft_h$nnraster\_rw$DENSEREGWEIGHT.$ii.ppm";
                verbose($cmd);
                system $cmd;
                }
            else
                {
                #$cmd="$DENSE2012 $SEGMENTDIR/$OUT.$ii.ppm 0 Segments$jj.ppm";
                $cmd="$DENSE2012 $SEGMENTDIR/$OUT.$ii.ppm 0 $OUT\_segments.$ii.ppm  0 $DENSEREGWEIGHT";
                verbose($cmd);
                system $cmd;
                #
                $cmd="mv $SEGMENTDIR/OchsBroxResults/$OUT.$ii\_dense.ppm $RESULTDIR/$OUT\_dense_rw$DENSEREGWEIGHT.$ii.ppm";
                verbose($cmd);
                system $cmd;
                #
                $cmd="mv $SEGMENTDIR/OchsBroxResults/$OUT.$ii\_dense_soft.ppm $RESULTDIR/$OUT\_dense_soft_rw$DENSEREGWEIGHT.$ii.ppm";
                verbose($cmd);
                system $cmd;
                }
            }
        }
    #clean
    $cmd="rm -r $SEGMENTDIR";
    verbose($cmd);
    #system $cmd;
    }
} #end DODENSE
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
if ($DOSEGMENTATION1)
    {
    #generate segmentation
    $SEGOUTDIR="$OOUTDIR/segmentation";
    if (-e "$SEGOUTDIR") {verbose("$SEGOUTDIR already exists");}
    else {$cmd="mkdir $SEGOUTDIR";system $cmd;}
    #
    $SEGMENTDIR="$OOUTDIR/dense";
    if (-e "$SEGMENTDIR") {verbose("$SEGMENTDIR already exists");}
    else {$cmd="mkdir $SEGMENTDIR";system $cmd;}
    #if ($IN_USE_SHOT) {$UUCM = "$UCMDIR/$SHOT";}
    #else {$UUCM = "$UCMDIR";}
    $UUCM = "$UCMDIR/$SHOT";
    @ucmt=split(/,/,$UCM_THRESHOLD);
    $nucmt=$#ucmt;
    print "ucm hierarchies : $nucmt\n";
    for ($k=0;$k <= $nucmt;$k++)
        {
        $kk=sprintf("%03d",$k);
        for ($i = $FFSTART ;$i <= $FFEND;$i++)
            {
            $ii=sprintf("%04d",$i);
            $j=$i-1;
            $jj=sprintf("%03d",$j);
            $cmd="$UCMBIN $UUCM/$UCM.$ii.ppm $ucmt[$k] $SEGOUTDIR/$OUT\_seg$k.$ii.ppm 2";
            #$cmd="$UCMBIN $UUCM/$UCM.$ii.ppm $ucmt[$k] $SEGOUTDIR/$OUT\_seg$kk.$ii.ppm 2";
            verbose($cmd);
            system $cmd;
            $cmd="$UCMBIN $UUCM/$UCM.$ii.ppm $ucmt[$k] $SEGOUTDIR/$OUT\_mean_seg$k.$ii.ppm 1 $DATADIR/$IN.$ii.ppm";
            verbose($cmd);
            #system $cmd;
            }
        }
    for ($i = $FFSTART ;$i <= $FFEND;$i++)
        {
        $ii=sprintf("%04d",$i);
        $j=$i-1;
        $jj=sprintf("%03d",$j);
        $cmd="cp $DATADIR/$OUT.$ii.ppm $SEGMENTDIR";
        verbose($cmd);
        system $cmd;
        for ($k=0;$k <= $nucmt;$k++)
            {
            $cmd="cp $SEGOUTDIR/$OUT\_seg$k.$ii.ppm $SEGMENTDIR/$OUT.$ii\_seg$k.ppm";
            verbose($cmd);
            system $cmd;
            }
        $cmd="cp $OOUTDIR/multicut/Segments$jj.ppm $SEGMENTDIR";
        verbose($cmd);
        system $cmd;
        #
        $cmd="$DENSE2012 $SEGMENTDIR/$OUT.$ii.ppm 3 Segments$jj.ppm";
        verbose($cmd);
        system $cmd;
        #
        $cmd="mv $SEGMENTDIR/OchsBroxResults/$OUT.$ii\_dense.ppm $SEGMENTDIR/OchsBroxResults/$OUT\dense.$ii.ppm";
        verbose($cmd);
        system $cmd;
        #
        $cmd="mv $SEGMENTDIR/OchsBroxResults/$OUT.$ii\_dense_soft.ppm $SEGMENTDIR/OchsBroxResults/$OUT\dense_soft.$ii.ppm";
        verbose($cmd);
        system $cmd;
        }
    }
    
if ($DOSLIC)
    {
    #
    $SEGMENTDIR="$OOUTDIR/dense";
    if (-e "$SEGMENTDIR") {verbose("$SEGMENTDIR already exists");}
    else {$cmd="mkdir $SEGMENTDIR";system $cmd;}
    $SSLIC = "$SLICDIR/$SHOT";
        for ($i = $FFSTART ;$i <= $FFEND;$i++)
        {
        $ii=sprintf("%04d",$i);
        $j=$i-1;
        $jj=sprintf("%03d",$j);
        #
        $cmd="cp $DATADIR/$OUT.$ii.ppm $SEGMENTDIR";
        verbose($cmd);
        system $cmd;
        #
        $cmd="$GMIC $SSLIC/$SLIC.$ii.png -o $SEGMENTDIR/$OUT.$ii\_seg0.ppm";
        verbose($cmd);
        system $cmd;
        #
        $cmd="cp $OOUTDIR/multicut/Segments$jj.ppm $SEGMENTDIR";
        verbose($cmd);
        system $cmd;
        #
        $cmd="$DENSE2012 $SEGMENTDIR/$OUT.$ii.ppm 1 Segments$jj.ppm";
        verbose($cmd);
        system $cmd;
        #
        $cmd="mv $SEGMENTDIR/OchsBroxResults/$OUT.$ii\_dense.ppm $SEGMENTDIR/OchsBroxResults/$OUT\dense.$ii.ppm";
        verbose($cmd);
        system $cmd;
        #
        $cmd="mv $SEGMENTDIR/OchsBroxResults/$OUT.$ii\_dense_soft.ppm $SEGMENTDIR/OchsBroxResults/$OUT\dense_soft.$ii.ppm";
        verbose($cmd);
        system $cmd;
        }
    }
