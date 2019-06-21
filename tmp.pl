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
$EXT="png";
$VERBOSE=0;
#preprocess
$SIZE=0;
$DOLOCALCONTRAST=0;
$ROLLING=0;
$BRIGHTNESS=0;
$CONTRAST=0;
$GAMMA=0;
$SATURATION=0;
#process params
$METHOD=1;
$DOPREPAREDATA=1;
#
$DOOPTICALFLOW=0;
$DOSEGMENTATION=0;
$DORASTERIZATION=0;
$RASTERIZATIONLEVELSTART=20;
$RASTERIZATIONLEVELEND=20;
$DOCOUNTLEVELS=0;
$DOMASKS=0;
$MASKLEVEL=40;
#
$DOCONCATMASK=0;
$MASKLIST="2,5,6,7,8";
$DOMINMAX=0;
$DODEXTR=0;
$DOPOTRACE=0;
$BLACKLEVEL=.5;
$BLUR=3;
$DOTRIMAP=0;
$TRIMAPDILATE=5;
$TRIMAPERODE=5;
$DOMATTING=0;
$KNN_NN=10;
$KNN_LAMBDA=100;
$GLOBALEXPAND=0;
#segmentation params
$FLOWWEIGHT=.2;
$TRESHOLD=.02;
$HIERARCHIES=40;

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
print AUTOCONF "#preprocess\n";
print AUTOCONF confstr(SIZE);
print AUTOCONF confstr(DOLOCALCONTRAST);
print AUTOCONF confstr(ROLLING);
print AUTOCONF confstr(BRIGHTNESS);
print AUTOCONF confstr(CONTRAST);
print AUTOCONF confstr(GAMMA);
print AUTOCONF confstr(SATURATION);
print AUTOCONF "#process\n";
print AUTOCONF confstr(METHOD);
print AUTOCONF "#0: David Sturtz #1: video_segment\n";
print AUTOCONF confstr(DOPREPAREDATA);
#print AUTOCONF confstr(DOOPTICALFLOW);
print AUTOCONF confstr(DOSEGMENTATION);
print AUTOCONF "#\n";
print AUTOCONF confstr(DORASTERIZATION);
print AUTOCONF confstr(RASTERIZATIONLEVELSTART);
print AUTOCONF confstr(RASTERIZATIONLEVELEND);
print AUTOCONF "#\n";
print AUTOCONF confstr(DOCOUNTLEVELS);
print AUTOCONF "#\n";
print AUTOCONF confstr(DOMASKS);
print AUTOCONF confstr(MASKLEVEL);
print AUTOCONF "#\n";
print AUTOCONF confstr(DOCONCATMASK);
print AUTOCONF confstr(MASKLIST);
print AUTOCONF "#\n";
print AUTOCONF confstr(DOPOTRACE);
print AUTOCONF confstr(BLUR);
print AUTOCONF confstr(BLACKLEVEL);
print AUTOCONF "#\n";
print AUTOCONF confstr(DOMINMAX);
print AUTOCONF confstr(DODEXTR);
print AUTOCONF "#\n";
print AUTOCONF confstr(DOTRIMAP);
print AUTOCONF confstr(TRIMAPDILATE);
print AUTOCONF confstr(TRIMAPERODE);
print AUTOCONF "#\n";
print AUTOCONF confstr(DOMATTING);
print AUTOCONF confstr(KNN_NN);
print AUTOCONF confstr(KNN_LAMBDA);
print AUTOCONF confstr(GLOBALEXPAND);
print AUTOCONF "#method0 only\n";
print AUTOCONF confstr(HIERARCHIES);
print AUTOCONF confstr(FLOWWEIGHT);
print AUTOCONF confstr(TRESHOLD);
print AUTOCONF "#misc\n";
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
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
  $MINMAX="/shared/foss-18/DEXTR-PyTorch/extractor/build/minmax";
  $DEXTR="python3 /shared/foss-18/DEXTR-PyTorch/demo.py";
  $VIDEOSEGMENT="/shared/foss-18/video_segment/bin/seg_tree_sample/seg_tree_sample";
  $SEGMENTVIEWER="/shared/foss-18/video_segment/bin/segment_viewer/segment_viewer";
  $SEGMENTCONVERT="/shared/foss-18/video_segment/bin/segment_converter/segment_converter";
  $ENV{LD_LIBRARY_PATH} = "/shared/foss-18/opencv-3.4.5_install/lib:$ENV{'LD_LIBRARY_PATH'}";
  $GLOBALMATTING="/shared/foss-18/global-matting/build/globalmatting";
  $ROBUSTMATTING="/shared/foss-18/RobustMatting/build/RobustMatting";
  $KNNMATTING="python /shared/foss-18/knn-matting/knn_matting.py";
  $POTRACE="/usr/bin/potrace";
  }
  
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
    }
    
print ("final seq : $FSTART $FEND\n");
#shot directories
if ($IN_USE_SHOT) {$IINDIR="$INDIR/$SHOT";}
else {$IINDIR="$INDIR/$SHOT";}
    
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

$FF=1;
for ($i = $FSTART ;$i <= $FEND;$i++)
    {
    $ii=sprintf("%04d",$i);
    $jj=sprintf("%04d",$FF);
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
    $cmd="$GMIC -i $IINDIR/$IN.$ii.$EXT $GMIC4 $GMIC1 $GMIC2 $GMIC3 -o $DATADIR/$OUT.$jj.png $LOG2";
    verbose($cmd);
    print BOLD YELLOW "frame : $i ";print RESET;
    print("-> preprocess input [size:$SIZE lce:$DOLOCALCONTRAST rolling:$ROLLING bcgs:$BRIGHTNESS/$CONTRAST/$GAMMA/$SATURATION]\n");
    system $cmd;
    $FF++;
    }
}#end preparedata

$FSTART=1;
$FEND=($FEND-$FSTART+1);
print ("shifted seq : $FSTART $FEND\n");

if ($METHOD == 0)
    {
    $FLOWDIR="$OOUTDIR/flow";
    if ($DOOPTICALFLOW)
        {

        if (-e "$FLOWDIR") {verbose("$FLOWDIR already exists");}
        else {$cmd="mkdir $FLOWDIR";system $cmd;}
        $cmd="$OFLOW_CLI --input-dir $DATADIR --output-dir $FLOWDIR";
        verbose($cmd);
        print BOLD YELLOW ("------------> processing opticalflow\n");print RESET;
        system $cmd;
        }#end doopticalflow

        $VISDIR="$OOUTDIR/vis";
        $SEGDIR="$OOUTDIR/segment";
        if ($DOSEGMENTATION)
            {
            $LENGTH=$FEND-2;
            $cmd="$SEGMENT_CLI --input-video $DATADIR --input-flow $FLOWDIR --length $LENGTH --flow-weight $FLOWWEIGHT --threshold $TRESHOLD --hierarchies $HIERARCHIES --vis-dir $VISDIR --output-dir $SEGDIR";
            verbose($cmd);
            print BOLD YELLOW ("------------> processing segmentation\n");print RESET;
            system $cmd;
            }
    }
    
if ($METHOD == 1)
    {
    $PBDIR="$OOUTDIR/videosegment";
    if ($DOSEGMENTATION)
        {
        if (-e "$PBDIR") {verbose("$PBDIR already exists");}
        else {$cmd="mkdir $PBDIR";system $cmd;}
        if (-e "$PBDIR/$IN.pb" && !$FORCE)
            {print BOLD RED "$PBDIR/$OUT.pb exists ... skipping\n";print RESET;}
        else {
            $cmd="$VIDEOSEGMENT --input_file=$DATADIR/$OUT.\%04d.png --output_file=$PBDIR/$OUT --logging --write_to_file";
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
            if ($METHOD == 0) {$FFEND=$FEND-1;} else {$FFEND=$FEND;}
            for ($i = $FSTART ;$i <= $FFEND;$i++)
                {
                $ii=sprintf("%04d",$i);
                $cmd="$GMIC $VISDIRLEV/$ii.png $SEGDIRLEV/$ii.png -split c -remove[2] -remove[2] -remove[2] -append c -o $VISDIRLEV/$ii.png";
                verbose($cmd);
                system $cmd;
                }
            }
        }
    }
    
if ($DOCOUNTLEVELS)
    {
    if ($METHOD == 0) {$FFEND=$FEND-1;} else {$FFEND=$FEND;}
    if ($METHOD == 1) {$HIERARCHIES=$RASTERIZATIONLEVELEND;}
    $cmd="$COUNTLEVELS $OOUTDIR/segment 0 $HIERARCHIES $FSTART $FFEND";
    verbose($cmd);
    system $cmd;
    }

if ($DOMASKS)
    {
    if ($METHOD == 0) {$FFEND=$FEND-1;} else {$FFEND=$FEND;}
    $cmd="$GENERATEMASK $OOUTDIR/segment $FSTART $FFEND $MASKLEVEL";
    verbose($cmd);
    system $cmd;
    }
            
if ($DOCONCATMASK)
    {
    $MASKDIR="$OOUTDIR/masks";
    if (-e "$MASKDIR") {verbose("$MASKDIR already exists");}
    else {$cmd="mkdir $MASKDIR";system $cmd;}
    @maskid=split(/,/,$MASKLIST);
    $masks=$#maskid;
    for ($i = $FSTART ;$i <= $FEND;$i++)
        {
        print ("image $i\n");
        $ii=sprintf("%04d",$i);
        $mm=sprintf("%03d",@maskid[0]);
        if (-e "$OOUTDIR/segment/$MASKLEVEL/mask_$mm.$ii.png")
        {
        $cmd="$GMIC $OOUTDIR/segment/$MASKLEVEL/mask_$mm.$ii.png -o $MASKDIR/concat.$ii.png";
        verbose ($cmd);
        system $cmd;
        }
        for ($m = 1 ;$m <= $masks;$m++)
            {
            $mm=sprintf("%03d",@maskid[$m]);
            #print ("merge mask @maskid[$m-1],@maskid[$m]\n");
            if (-e "$OOUTDIR/segment/$MASKLEVEL/mask_$mm.$ii.png")
            {
            $cmd="$GMIC $MASKDIR/concat.$ii.png $OOUTDIR/segment/$MASKLEVEL/mask_$mm.$ii.png -add -o $MASKDIR/concat.$ii.png";
            verbose ($cmd);
            system $cmd;
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
    if ($METHOD == 0) {$FFEND=$FEND-1;} else {$FFEND=$FEND;}
        for ($i = $FSTART ;$i <= $FFEND;$i++)
        {
        $ii=sprintf("%04d",$i);
        $I=1;
        $cmd="$GMIC $OOUTDIR/masks/compo.$ii.png -b $BLUR -o $WORKDIR/$I.pgm";
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
        $cmd="$GMIC $POUT -to_colormode 3 -o $OOUTDIR/masks/compo_potrace.$ii.png $LOG2";
        verbose($cmd);
        system $cmd;
        }
    }
    
if ($DOMINMAX)
    {
    if ($METHOD == 0) {$FFEND=$FEND-1;} else {$FFEND=$FEND;}
    $cmd="$MINMAX $OOUTDIR/masks/compo $FSTART $FFEND $MASKLEVEL";
    verbose($cmd);
    system $cmd;
    }

if ($DODEXTR)
{
if ($METHOD == 0) {$FFEND=$FEND-1;} else {$FFEND=$FEND;}
for ($i = $FSTART ;$i <= $FFEND;$i++)
    {
    $ii=sprintf("%04d",$i);
    $cmd="$DEXTR --in $DATADIR/$OUT.$ii.png --minmax $OOUTDIR/masks/compo_minmax.$ii.txt --out $OOUTDIR/masks/compo_dextr.$ii.png";
    verbose($cmd);
    system $cmd;
    }
}

if ($DOTRIMAP)
    {
    $MATTEDIR="$OOUTDIR/matting";
    if (-e "$MATTEDIR") {verbose("$MATTEDIR already exists");}
    else {$cmd="mkdir $MATTEDIR";system $cmd;}
    if ($METHOD == 0) {$FFEND=$FEND-1;} else {$FFEND=$FEND;}
    for ($i = $FSTART ;$i <= $FFEND;$i++)
        {
        $ii=sprintf("%04d",$i);
        $cmd="$GMIC $OOUTDIR/masks/compo_dextr.$ii.png --erode_circ[0] $TRIMAPERODE --dilate_circ[0] $TRIMAPDILATE,0 -remove[0] -div 1.99 -add -cut 0,255 -o $MATTEDIR/trimap.$ii.png";
        #$cmd="$GMIC $OOUTDIR/masks/compo.$ii.png $OOUTDIR/masks/compo_dextr.$ii.png -erode[0] $TRIMAPERODE -dilate[1] $TRIMAPDILATE -div 1.99 -add -cut 0,255 -o $MATTEDIR/trimap.$ii.png";
        verbose($cmd);
        system $cmd;
        }
    }
  
if ($DOMATTING)
    {
    $MATTEDIR="$OOUTDIR/matting";
    if (-e "$MATTEDIR") {verbose("$MATTEDIR already exists");}
    else {$cmd="mkdir $MATTEDIR";system $cmd;}
    if ($METHOD == 0) {$FFEND=$FEND-1;} else {$FFEND=$FEND;}
    for ($i = $FSTART ;$i <= $FFEND;$i++)
        {
        $ii=sprintf("%04d",$i);
        #-----------------------------#
        ($s1,$m1,$h1)=localtime(time);
        #-----------------------------#
        
#        $cmd="$GLOBALMATTING $DATADIR/$OUT.$ii.$EXT $MATTEDIR/trimap.$ii.png $MATTEDIR/global_alpha_exp$GLOBALEXPAND.$ii.png  $MATTEDIR/global_alpha_exp$GLOBALEXPAND\_filter.$ii.png $GLOBALEXPAND";
#        verbose($cmd);
#        print("--------> global matting [expand:$GLOBALEXPAND]\n");
#        system $cmd;
        $cmd="$ROBUSTMATTING $DATADIR/$OUT.$ii.png $MATTEDIR/trimap.$ii.png $MATTEDIR/robust_alpha.$ii.png";
        verbose($cmd);
        print("--------> robust matting\n");
        system $cmd;
#        $cmd="$KNNMATTING $DATADIR/$OUT.$ii.$EXT $MATTEDIR/trimap.$ii.png $MATTEDIR/knn_alpha_lambda$KNN_LAMBDA\_nn$KNN_NN\.$ii.png $KNN_LAMBDA $KNN_NN";
#        verbose($cmd);
#        print("--------> knn matting [lambda:$KNN_LAMBDA nn:$KNN_NN]\n");
#        system $cmd;
        #-----------------------------#
        ($s2,$m2,$h2)=localtime(time);
        ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
        #afanasy parsing format
        print BOLD YELLOW "Writing $MATTEDIR/alpha.$ii.png took $hlat:$mlat:$slat\n";print RESET;
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
