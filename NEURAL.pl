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

#pour keyframe
$keycount=0;
$PRINT=0;
#defaults
$FSTART="auto";
$FEND="auto";
$FSTEP=1;
$SHOT="";
$IN_USE_SHOT=0;
$OUT_USE_SHOT=0;
$CONTENTDIR="$CWD/originales";
$CONTENT="ima";
$DOEDGES=0;
$EDGEDIR="$CWD/edges";
$EDGES="edges";
$EDGEDILATE=0;
$EDGESMOOTH=1;
$EDGESOPACITY=1;
$EDGESMODE="add";
$EDGESINVERT=0;
$NOISEDIR="$CWD/noise";
$NOISEPIC="noise";
$NOISEEXT="exr";
$GRADIENTDIR="$CWD/gradient";
$GRADIENT="gradient";
$GRADIENTEXT="exr";
$STYLEDIR="$CWD/styles";
$STYLE="style.jpg";
$STYLESCALE="8e-1";
$OUTDIR="$CWD/neural";
$ZEROPAD=1;
$FORCE=0;
$EXT="png";
$VERBOSE=0;
#hyperparameter
$SIZE=720;
$CONTENT_WEIGHT=1;
$STYLE_RATIO=2000;
$STYLE_WEIGHT="\$STYLE_RATIO*\$CONTENT_WEIGHT";
$TV_WEIGHT="1e-6";
$STYLE_LAYER="relu1_1,relu2_1,relu3_1,relu4_1,relu5_1";
$CONTENT_LAYER="relu4_2";
$INIT="image"; #image or random
$SEED=`date +%N`;$SEED/=1000000000;
#process
$NUMITER=300;
$SAVEITER=50;
$PRINTITER="\$SAVEITER";
#network
$OPTIMIZER="adam"; # adam lbfgs
$LEARNING_RATE=2;	#for adam optimisation
$POOLING="avg"; #max avg
$NORMALIZE_GRADIENT=1;
$MODEL="VGG19"; #VGG19N VGG19 FACE
$PARAMS="_iter\$NUMITER\\_cweight\$CONTENT_WEIGHT\\_style\$STYLE_RATIO";
#preprocess
$CONTENTBLUR=0;
$BRIGHTNESS=0;
$CONTRAST=0;
$GAMMA=0;
$SATURATION=0;
$DOCOLORTRANSFERT=0;
$LCTMODE="pca";
#reindex result
$DOINDEX=0;
$INDEXCOLOR=64;
$INDEXMETHOD=1;
$DITHERING=1;
$INDEXROLL=5;
$DOLOCALCONTRAST=1;
$NOISE=0;
#postprocess
$DOMEDIANFILTER=0;
$MEDIANRADIUS=2;
$MEDIANREPEAT=1;
$CLEAN=1;
$CSV=0;
#gpu id
$GPU=0; #-1 -> CPU only 0 -> GPU
$LOG1=" > /var/tmp/neural_$GPU.log";
$LOG2=" 2> /var/tmp/neural_$GPU.log";

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
open (AUTOCONF,">","neural_auto.conf");
print AUTOCONF confstr(PROJECT);
print AUTOCONF confstr(FSTART);
print AUTOCONF confstr(FEND);
print AUTOCONF confstr(FSTEP);
print AUTOCONF confstr(SHOT);
print AUTOCONF confstr(IN_USE_SHOT);
print AUTOCONF confstr(OUT_USE_SHOT);
print AUTOCONF confstr(CONTENTDIR);
print AUTOCONF confstr(CONTENT);
print AUTOCONF confstr(DOEDGES);
print AUTOCONF confstr(EDGEDIR);
print AUTOCONF confstr(EDGES);
print AUTOCONF confstr(EDGEDILATE);
print AUTOCONF confstr(EDGESMOOTH);
print AUTOCONF confstr(EDGESOPACITY);
print AUTOCONF confstr(EDGESMODE);
print AUTOCONF confstr(EDGESINVERT);
print AUTOCONF confstr(NOISEDIR);
print AUTOCONF confstr(NOISEPIC);
print AUTOCONF confstr(NOISEEXT);
print AUTOCONF confstr(GRADIENTDIR);
print AUTOCONF confstr(GRADIENT);
print AUTOCONF confstr(GRADIENTEXT);
print AUTOCONF confstr(STYLEDIR);
print AUTOCONF confstr(STYLE);
print AUTOCONF confstr(STYLESCALE);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF "#hyperparameter\n";
print AUTOCONF confstr(SIZE);
print AUTOCONF confstr(CONTENT_WEIGHT);
print AUTOCONF confstr(STYLE_RATIO);
print AUTOCONF "\$STYLE_WEIGHT=\$STYLE_RATIO*\$CONTENT_WEIGHT;\n";
print AUTOCONF confstr(TV_WEIGHT);
print AUTOCONF confstr(STYLE_LAYER);
print AUTOCONF confstr(CONTENT_LAYER);
print AUTOCONF confstr(INIT);
print AUTOCONF confstr(SEED);
print AUTOCONF "#process\n";
print AUTOCONF confstr(NUMITER);
print AUTOCONF confstr(SAVEITER);
print AUTOCONF confstr(PRINTITER);
print AUTOCONF "#network\n";
print AUTOCONF confstr(OPTIMIZER);
print AUTOCONF confstr(LEARNING_RATE);
print AUTOCONF confstr(POOLING);
print AUTOCONF confstr(NORMALIZE_GRADIENT);
print AUTOCONF confstr(MODEL);
print AUTOCONF "\$PARAMS=\"_ssc\$STYLESCALE\";\n";
print AUTOCONF "#preprocess\n";
print AUTOCONF confstr(CONTENTBLUR);
print AUTOCONF confstr(BRIGHTNESS);
print AUTOCONF confstr(CONTRAST);
print AUTOCONF confstr(GAMMA);
print AUTOCONF confstr(SATURATION);
print AUTOCONF confstr(DOCOLORTRANSFERT);
print AUTOCONF "#0 : no transfert\n";
print AUTOCONF "#1 : color_transfer\n";
print AUTOCONF "#2 : hmap\n";
print AUTOCONF "#3 : Neural-tools\n";
print AUTOCONF "#reindex\n";
print AUTOCONF confstr(DOINDEX);
print AUTOCONF confstr(INDEXCOLOR);
print AUTOCONF confstr(INDEXMETHOD);
print AUTOCONF confstr(DITHERING);
print AUTOCONF confstr(INDEXROLL);
print AUTOCONF "#4 : ideepcolor\n";
print AUTOCONF confstr(DOLOCALCONTRAST);
print AUTOCONF confstr(NOISE);
print AUTOCONF "#postprocess\n";
print AUTOCONF confstr(DOMEDIANFILTER);
print AUTOCONF confstr(MEDIANRADIUS);
print AUTOCONF confstr(MEDIANREPEAT);
print AUTOCONF "#more\n";
print AUTOCONF confstr(CLEAN);
print AUTOCONF confstr(CSV);
print AUTOCONF "#gpu id\n";
print AUTOCONF confstr(GPU);
print AUTOCONF "1\n";
}

#arguments
if ($#ARGV == -1) {
	print "usage: $scriptname \n";
	print "-autoconf\n";
	print "-conf file.conf\n";
	print "-f startframe endframe\n";
	print "-step step[1]\n";
	print "-force [0]\n";
	print "-verbose\n";
    print "-gpu gpu_id [0]\n";
	print "-csv csv_file.csv\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-autoconf") 
    {
    print "writing neural_auto.conf : mv neural_auto.conf neural.conf\n";
    autoconf();
    if (-e "$OUTDIR") {print "$OUTDIR already exists\n";}
    else {$cmd="mkdir $OUTDIR";system $cmd;}
    if (-e "$STYLEDIR") {print "$STYLEDIR already exists\n";}
    else {$cmd="mkdir $STYLEDIR";system $cmd;}
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
  if (@ARGV[$arg] eq "-step") 
    {
    $FSTEP=@ARGV[$arg+1];
    print "step $FSTEP\n";
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
  if (@ARGV[$arg] eq "-gpu") 
    {
    $GPU=@ARGV[$arg+1];
    $LOG1=" > /var/tmp/neural_$GPU.log";
    $LOG2=" 2> /var/tmp/neural_$GPU.log";
    print "gpu id : $GPU\n";
    }
  if (@ARGV[$arg] eq "-size") 
    {
    $SIZE=@ARGV[$arg+1];
    print "size : $SIZE\n";
    }
 if (@ARGV[$arg] eq "-verbose") 
    {
    $VERBOSE=1;
    $LOG1="";
    $LOG2="";
    print "verbose ...\n";
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
  $LUA="/shared/foss/neural-style/neural_style.lua";
  $TH="/shared/foss/torch/install/bin/th";
  $MODELDIR="/shared/foss/neural-style/models";
  $IDEEPCOLOR="/usr/bin/python /shared/foss/ideepcolor/GlobalHistogramTransfer.py";
  $PROTOTXT="/shared/foss/ideepcolor/models/global_model/deploy_nodist.prototxt";
  $CAFFEMODEL="/shared/foss/ideepcolor/models/global_model/global_model.caffemodel";
  $GLOBPROTOTXT="/shared/foss/ideepcolor/models/global_model/global_stats.prototxt";
  $GLOBCAFFEMODEL="/shared/foss/ideepcolor/models/global_model/dummy.caffemodel";
  $COLOR_TRANSFER="/shared/foss/color_transfer/color_transfer.py";
  $HMAP="/shared/foss/hmap/hmap_c.py";
  $LINEARCOLORTRANSFERT="/shared/foss/Neural-Tools/linear-color-transfer.py";
  $ENV{PYTHONPATH} = "/shared/foss/caffe-cpu/python:/shared/foss/ideepcolor/caffe_files:$ENV{'PYTHONPATH'}";
  verbose("PYTHONPATH : $ENV{'PYTHONPATH'}");
  }
  
if ($userName eq "dev18")	#
  {
  $GMIC="/usr/bin/gmic";
  $LUA="/shared/foss-18/neural-style/neural_style.lua";
  $TH="/shared/foss-18/torch/install/bin/th";
  $MODELDIR="/shared/foss-18/neural-style/models";
  $IDEEPCOLOR="/usr/bin/python3 /shared/foss-18/ideepcolor/GlobalHistogramTransfer.py";
  $PROTOTXT="/shared/foss-18/ideepcolor/models/global_model/deploy_nodist.prototxt";
  $CAFFEMODEL="/shared/foss-18/ideepcolor/models/global_model/global_model.caffemodel";
  $GLOBPROTOTXT="/shared/foss-18/ideepcolor/models/global_model/global_stats.prototxt";
  $GLOBCAFFEMODEL="/shared/foss-18/ideepcolor/models/global_model/dummy.caffemodel";
  $COLOR_TRANSFER="/shared/foss-18/color_transfer/color_transfer.py";
  $HMAP="/shared/foss-18/hmap/hmap.py";
  $LINEARCOLORTRANSFERT="/shared/foss-18/Neural-Tools/linear-color-transfer.py";
  $ENV{PYTHONPATH} = "/shared/foss-18/caffe/python:/shared/foss-18/ideepcolor/caffe_files:$ENV{'PYTHONPATH'}";
  $ENV{LD_LIBRARY_PATH} = "/shared/foss-18/caffe/build/lib:$ENV{'LD_LIBRARY_PATH'}";
  verbose("PYTHONPATH : $ENV{'PYTHONPATH'}");
  }
  
if ($userName eq "lulu")	#
  {
  $GPU=-1;
  $GMIC="/usr/bin/gmic";
  $LUA="/shared/foss/neural-style/neural_style.lua";
  $TH="/shared/foss/torch-multi/install/bin/th";
  $MODELDIR="/shared/foss/neural-style/models";
  $IDEEPCOLOR="/usr/bin/python /shared/foss/ideepcolor/GlobalHistogramTransfer.py";
  $PROTOTXT="/shared/foss/ideepcolor/models/global_model/deploy_nodist.prototxt";
  $CAFFEMODEL="/shared/foss/ideepcolor/models/global_model/global_model.caffemodel";
  $GLOBPROTOTXT="/shared/foss/ideepcolor/models/global_model/global_stats.prototxt";
  $GLOBCAFFEMODEL="/shared/foss/ideepcolor/models/global_model/dummy.caffemodel";
  $ENV{PYTHONPATH} = "/shared/foss/caffe-cpu/python:/shared/foss/ideepcolor/caffe_files:$ENV{'PYTHONPATH'}";
  verbose("PYTHONPATH : $ENV{'PYTHONPATH'}");
  }

sub neural {

#auto frames
if ($FSTART eq "auto" || $FEND eq "auto")
    {
    if ($IN_USE_SHOT) {$AUTODIR="$CONTENTDIR/$SHOT";} else {$AUTODIR="$CONTENTDIR";}
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
    
$OOUTDIR="$OUTDIR/$SHOT";
if (-e "$OOUTDIR") {print "$OOUTDIR already exists\n";}
else {$cmd="mkdir $OOUTDIR";system $cmd;}

#finalframe
$SSTYLE=$STYLE;
$SSTYLE=~ s/.jpg//;
$SSTYLE=~ s/.jpeg//;
$SSTYLE=~ s/.png//;
$SSTYLE=~ s/\.//;
@tmp=split(/\./,$CONTENT);
$CCONTENT=@tmp[0];


for ($i=$FSTART ; $i <= $FEND ; $i=$i+$FSTEP)
{
$ii=sprintf("%04d",$i);
#keyframes
if (-e "$CONF.key")
    {
    $PRINT=1;
    #shunte numerotation
    $ii=sprintf("%04d",$FSTART);
    #
    verbose("keyframe mode");
    require "$CONF.key";
    ${$KEYNAME}=keyframe($KEYSAFE);
    print BOLD RED "$KEYNAME = ${$KEYNAME}\n";print RESET;
    $keycount++;
    if ($keycount > $KEYFRAME) {last;}
    }
#get input elements ,if keyframe mode $ii = $FSTART
$INCONTENT="$CONTENTDIR/$SHOT/$CONTENT.$ii.$EXT";
$INEDGES  ="$EDGEDIR/$SHOT/$EDGES.$ii.$EXT";
#reinit $ii if keyframe mode was on
$ii=sprintf("%04d",$i);
#working dir
$WORKDIR="$OOUTDIR/w$ii";
$WCONTENT  ="$WORKDIR/preprocess.$EXT";
$WCOLOR    ="$WORKDIR/colortransfert.$EXT";
$WEDGES    ="$WORKDIR/edges.$EXT";
$WNEURAL   ="$WORKDIR/neural.$EXT";
#output
$FINALFRAME="$OOUTDIR/$CCONTENT\_$SSTYLE$PARAMS.$ii.$EXT";

if (-e $FINALFRAME && !$FORCE)
   {print BOLD RED "frame $FINALFRAME exists ... skipping\n";print RESET;}
else
  {
  $touchcmd="touch $FINALFRAME";
  system $touchcmd;
  print BOLD BLUE ("\nframe : $ii\n");print RESET;
  if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
#preprocessing content --> $WCONTENT
  if ($CONTENTBLUR != 0) 
    {$GMIC1="-fx_sharp_abstract $CONTENTBLUR,10,0.5,0,0";} else {$GMIC1="";}
  if (($BRIGHTNESS != 0) || ($CONTRAST != 0) || ($GAMMA != 0) || ($SATURATION != 0)) 
    {$GMIC2="-fx_adjust_colors $BRIGHTNESS,$CONTRAST,$GAMMA,0,$SATURATION";} else {$GMIC2="";}
  if ($DOLOCALCONTRAST) 
    {$GMIC3="-fx_LCE[0] 80,0.5,1,1,0,0";} else {$GMIC3="";}
  $cmd="$GMIC -i $INCONTENT $GMIC1 -resize2dx $SIZE $GMIC2 $GMIC3 -o $WCONTENT $LOG2";
  print("--------> preprocess [blur:$CONTENTBLUR b/c/g/s:$BRIGHTNESS,$CONTRAST,$GAMMA,$SATURATION lce:$DOLOCALCONTRAST]\n");
  verbose($cmd);
  system $cmd;
  
#color transfert --> $WCOLOR
  if ($DOCOLORTRANSFERT == 0)
    {
    verbose("no color transfert");
    $cmd="cp $WCONTENT $WCOLOR";
    #$cmd="$GMIC -i $WCONTENT -to_colormode 1 -o $WCOLOR $LOG2";
    print("--------> no color transfert []\n");
    verbose($cmd);
    system $cmd;
    }
  if ($DOCOLORTRANSFERT == 1)
    {
    verbose("color transfert : using color_transfer");
    $cmd="python $COLOR_TRANSFER -s $STYLEDIR/$STYLE -t $WCONTENT -o $WCOLOR";
    print("--------> color_transfer [style:$STYLE]\n");
    verbose($cmd);
    system $cmd;
    }
  if ($DOCOLORTRANSFERT == 2)
    {
    verbose("color transfert : using hmap");
    $cmd="python $HMAP $WCONTENT $STYLEDIR/$STYLE $WCOLOR";
    print("--------> hmap [style:$STYLE]\n");
    verbose($cmd);
    system $cmd;
    }
  if ($DOCOLORTRANSFERT == 3)
    {
    verbose("color transfert : using neural-tools");
    $cmd="python $LINEARCOLORTRANSFERT --mode $LCTMODE --target_image $WCONTENT --source_image $STYLEDIR/$STYLE --output_image $WCOLOR";
    print("--------> neural-tools [mode:$LCTMODE style:$STYLE]\n");
    verbose($cmd);
    system $cmd;
    if ($DOINDEX)
        {
        $cmd="$GMIC $STYLEDIR/$STYLE -colormap $INDEXCOLOR,$INDEXMETHOD,1 $WCOLOR -index[1] [0],1,$DITHERING -remove[0] -fx_sharp_abstract $INDEXROLL,10,0.5,0,0 -o $WCOLOR $LOG2";
        verbose($cmd);
        print("--------> indexing [colors:$INDEXCOLOR method:$INDEXMETHOD dither:$DITHERING rolling:$INDEXROLL]\n");
        system $cmd;
        }
    }
  if ($DOCOLORTRANSFERT == 4)
    {
    verbose("color transfert : using ideepcolor");
    $cmd="$IDEEPCOLOR $WCONTENT $STYLEDIR/$STYLE $WCOLOR $PROTOTXT $CAFFEMODEL $GLOBPROTOTXT $GLOBCAFFEMODEL 2> /var/tmp/cnnmrf_$GPU.log";
    #$cmd="$IDEEPCOLOR $WCONTENT $STYLEDIR/$STYLE $WCOLOR $PROTOTXT $CAFFEMODEL $GLOBPROTOTXT $GLOBCAFFEMODEL";
    print("--------> ideepcolor [style:$STYLE]\n");
    verbose($cmd);
    system $cmd;
    }
  
#process edges --> $WEDGES
if($DOEDGES)
  {
  if ($EDGEDILATE != 0) 
    {$GMIC1="-dilate $EDGEDILATE";} else {$GMIC1="";}
  if ($EDGESMOOTH != 0) 
    {$GMIC2="-fx_dreamsmooth 10,0,1,1,0,0.8,0,24,0";} else {$GMIC2="";}
if ($EDGESINVERT != 0) 
    {$GMIC3="-n 0,1 -oneminus -n 0,255";} else {$GMIC3="";}
  $cmd="$GMIC -i $INEDGES -to_colormode 3 $GMIC1 -resize2dx $SIZE,5 $GMIC2 $GMIC3 -o $WEDGES $LOG2";
  print("--------> preprocess edges [dilate:$EDGEDILATE dreamsmooth:$EDGESMOOTH]\n");
  verbose($cmd);
  system $cmd;
#add edges
  $cmd="$GMIC -i $WCOLOR -i $WEDGES -blend $EDGESMODE,$EDGESOPACITY -o $WCOLOR $LOG2";
#  $cmd="$GMIC -i $WCOLOR -i $WEDGES -n[1] 0,1 -oneminus[1] -n[1] 0,255 -blend multiply,$EDGESOPACITY -o $WCOLOR $LOG2";
  print("--------> add edges [mode:$EDGESMODE opacity:$EDGESOPACITY]\n");
  verbose($cmd);
  system $cmd;
  }
if ($NOISETYPE != 0) 
{
  #$cmd="$GMIC -i $WCOLOR -fx_noise $NOISE,0,0,1,0 -o $WCOLOR $LOG2";
  #print("--------> add noise [noise intensity:$NOISE]\n");
  $cmd="$GMIC -i $WCOLOR fx_emulate_grain $NOISETYPE,1,$NOISESTRENGTH,$NOISESCALE,0,0,0,0,0,0,0,0 -o $WCOLOR $LOG2";
  print("--------> add noise [noise type:$NOISETYPE strength:$NOISESTRENGTH scale:$NOISESCALE]\n");
  verbose($cmd);
  system $cmd;
  }
  
#neural transfert --> $WNEURAL
  $jcjcmd="$TH $LUA -style_image $STYLEDIR/$STYLE -content_image $WCOLOR -content_weight $CONTENT_WEIGHT -style_weight $STYLE_WEIGHT -image_size $SIZE -gpu $GPU -output_image $WNEURAL -print_iter $PRINTITER -save_iter $SAVEITER -num_iterations $NUMITER -optimizer $OPTIMIZER -pooling $POOLING -style_scale $STYLESCALE -tv_weight $TV_WEIGHT -seed $SEED -content_layers $CONTENT_LAYER -style_layers $STYLE_LAYER -init $INIT";
  #more options
  if ($OPTIMIZER eq "adam")
  {$jcjcmd=$jcjcmd." -learning_rate $LEARNING_RATE";}
  if ($GPU >= 0)
  {$jcjcmd=$jcjcmd." -backend cudnn -cudnn_autotune";}
  if ($NORMALIZE_GRADIENT)
  {$jcjcmd=$jcjcmd." -normalize_gradients";}
  if ($MODEL eq "VGG19")
  {$jcjcmd=$jcjcmd." -proto_file $MODELDIR/VGG_ILSVRC_19_layers_deploy.prototxt -model_file $MODELDIR/VGG_ILSVRC_19_layers.caffemodel";}
  if ($MODEL eq "VGG19N")
  {$jcjcmd=$jcjcmd." -proto_file $MODELDIR/VGG_ILSVRC_19_layers_deploy.prototxt -model_file $MODELDIR/vgg_normalised.caffemodel";}
  if ($MODEL eq "FACE")
  {$jcjcmd=$jcjcmd." -proto_file $MODELDIR/VGG_FACE_deploy.prototxt -model_file $MODELDIR/VGG_FACE.caffemodel";}
  $jcjcmd=$jcjcmd." $LOG1";
  verbose($jcjcmd);
  #-----------------------------#
  ($s1,$m1,$h1)=localtime(time);
  #-----------------------------#
  system $jcjcmd;
  #postprocess
  if ($DOMEDIANFILTER) 
    {$GMIC1="-iain_recursive_median_p $MEDIANRADIUS,$MEDIANREPEAT,0,0,1";} else {$GMIC1="";}
  $cmd="$GMIC -i $WNEURAL $GMIC1 -o $WNEURAL $LOG2";
  verbose($cmd);
  system $cmd;
  #final
  $cmd="cp $WNEURAL $FINALFRAME";
  verbose($cmd);
  system $cmd;
    if ($PRINT)
    {
    $val=sprintf("%.02f",${$KEYNAME});
    $printcmd="$GMIC -i $FINALFRAME -text_outline \"$KEYNAME...$val\" -o $FINALFRAME $LOG";
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
  print BOLD YELLOW "\nWriting  NEURAL $ii took $hlat:$mlat:$slat \n";print RESET;
  #-----------------------------#
  }
}
}#neural sub

#main
if ($CSV)
  {
  open (CSV , "$CSVFILE");
  while ($line=<CSV>)
    {
    chop $line;
    @line=split(/,/,$line);
    $SHOT=@line[0];
    $STYLE=@line[1];
    $FSTART=@line[3];
    $FEND=@line[4];
    $LENGTH=@line[5];   
    $process=@line[6];
    $suffix=@line[7];
    if ($process)
      {
      neural();
      }
    }
   }
else
  {
  neural();
  }

# gestion des keyframes
sub keyframe {
    @keyvals = split(/,/,$_[0]);
    #print "keyvals = @keyvals\n";
    $key1=$keyvals[0];
    $key2=$keyvals[1];
    #print ("key1 = $key1\n");
    #print ("key2 = $key2\n");
    #print ("keycount = $keycount\n");
    #print ("KEYFRAME = $KEYFRAME\n");
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
