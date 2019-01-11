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
$CONTENTDIR="$CWD/originales";
$CONTENT="ima";
$IN_USE_SHOT=0;
$DOEDGES=0;
$EDGEDIR="$CWD/edges";
$EDGES="edges";
$EDGEDILATE=0;
$EDGESMOOTH=1;
$EDGESOPACITY=1;
$EDGESMODE="add";
$EDGESINVERT=0;
$STYLEDIR="$CWD/styles";
$STYLE="style.jpg";
$STYLESCALE="1";
$OUTDIR="$CWD/cnnmrf";
$ZEROPAD=1;
$FORCE=0;
$EXTIN="png";
$EXTOUT="png";
$EXTEDGES="png";
#$EXT="png";
$VERBOSE=0;
$SIZE=720;
#network
$NORMALIZE_GRADIENT=1;
$POOLING="avg";
$OPTIMIZER="adam";   #adam,lbfgs
$LEARNING_RATE=5;
$INI_METHOD="image";  #image,random
$TYPE="transfer";
$MODE="speed";
#hyperparameters
$NUMRES="2";
$NUMITER="50";
$MRFLAYERS="21";
#$MRFLAYERS="12,21";
$MRFW="1e-3"; #1e-4 if not normalize gradient
$MRFWEIGHT="$MRFW,$MRFW";
$MRFP=1;
$MRFPATCHSIZE="$MRFP,$MRFP";
$NUMROT="0";
$NUMSCALE="0";
$TARGETSTRIDE="1,1";
$SOURCESTRIDE="1,1";
$MRFC=0;
$MRFCONFIDENCE="$MRFC,$MRFC";
$CONTENTLAYER="21";
$CONTENTWEIGHT="2000";
$TVWEIGHT="1e-1";
$GPUCHUNK1="256";
$GPUCHUNK2="16";
#heavy params line
$PARAMS="_mrfp$MRFP\_mrfw$MRFW\_mrfc$MRFC\_cw$CONTENTWEIGHT\_sc$STYLESCALE\_rot$NUMROT\_scale$NUMSCALE\_iter$ITERS\_$INI_METHOD\_grad$NORMALIZE_GRADIENT\_$POOLING\_$OPTIMIZER";
#light params line
$PARAMS="_mrfp$MRFP\_ssc$STYLESCALE\_lr$LEARNING_RATE\_iter$ITERS";
#preprocess
$CONTENTBLUR=0;
$BRIGHTNESS=0;
$CONTRAST=0;
$GAMMA=0;
$SATURATION=0;
$DOCOLORTRANSFERT=0;
$LCTMODE="pca";
$DOLOCALCONTRAST=1;
$DOEQUALIZE=0;
$EQUALIZELEVEL=256;
$EQUALIZEMIN=0;
$EQUALIZEMAX=255;
$NOISETYPE=0;
$NOISESTRENGTH=1;
$NOISESCALE=100;
#postprocess
$DOMEDIANFILTER=0;
$MEDIANRADIUS=2;
$MEDIANREPEAT=1;
$CLEAN=1;
$CSV=0;
#gpu id
$DEV=1;
$KEEPLEVEL2=0;
$KEEPCOLORTRANSFERT=0;
$GPU=0;
$LOG1=" > /var/tmp/cnnmrf_$GPU.log";
$LOG2=" 2> /var/tmp/cnnmrf_$GPU.log";

sub printhelp {
print "Basic options:\n";
print GREEN ; print "-content_name :";print RESET;print" The content image\n";
print GREEN ; print "-style_name   :";print RESET;print" The style image\n";
print GREEN ; print "-ini_method   :";print RESET;print" [image] \nInitial method, set to \'image\' to use the content image as the initialization; set to \'random\' to use random noise.\n";
print GREEN ; print "-type         :";print RESET;print" [transfer] \nUse Guided Synthesis (transfer) or Un-guided Synthesis (syn)\n";
print GREEN ; print "-max_size     :";print RESET;print" [640] \nMaximum size of the image. Larger image needs more time and memory.\n";
print GREEN ; print "-backend      :";print RESET;print" [cudnn] \nUse \'cudnn\' for CUDA-enabled GPUs or \'clnn\' for OpenCL.\n";
print GREEN ; print "-mode         :";print RESET;print" [speed] \nTry \'speed\' if you have a GPU with more than 4GB memory, and try \'memory\' otherwise. The \'speed\' mode is significantly faster (especially for synthesizing high resolutions) at the cost of higher GPU memory.\n";
print GREEN ; print "-num_res      :";print RESET;print" [3] \nNumber of resolutions. Notice the lowest resolution image should be larger than the patch size otherwise it won\'t synthesize.\n";
print GREEN ; print "-num_iter     :";print RESET;print" [100,100,100] \nNumber of iterations for each resolution. You can use comma-separated values.\n\n";

print "Advanced options:\n";
print GREEN ; print "-mrf_layers   :";print RESET;print" [12,21] \nThe layers for MRF constraint. Usually layer 21 alone already gives decent results. Including layer 12 may improve the results but at significantly more computational cost. You can use comma-separated values.\n";
print GREEN ; print "-mrf_weight    :";print RESET;print" [1e-4,1e-4] \nWeight for each MRF layer. Higher weights leads to more style faithful results. You can use comma-separated values.\n";
print GREEN ; print "-mrf_patch_size :";print RESET;print" [3,3] \nThe patch size for MRF constraint. This value is defined seperately for each MRF layer. You can use comma-separated values. \n";
print GREEN ; print "-target_num_rotation :";print RESET;print" [0] \nTo matching objects of different poses. This value is shared by all MRF layers. The total number of rotational copies is \"2 * mrf_num_rotation + 1\"\n";
print GREEN ; print "-target_num_scale :";print RESET;print" [0] \nTo matching objects of different scales. This value is shared by all MRF layers. The total number of scaled copies is \"2 * mrf_num_scale + 1\" \n";
print GREEN ; print "-target_sample_stride :";print RESET;print" [2,2] \nStride to sample mrf on style image. This value is defined seperately for each MRF layer. You can use comma-separated values. \n";
print GREEN ; print "-mrf_confidence_threshold :";print RESET;print" [0,0] \nThreshold for filtering out bad matching. Default value 0 means we keep all matchings. This value is defined seperately for all layers. You can use comma-separated values. \n";
print GREEN ; print "-source_sample_stride :";print RESET;print" [2,2] \nStride to sample mrf on synthesis image. This value is defined seperately for each MRF layer. This settings is relevant only for syn setting. You can use comma-separated values. \n\n";

print GREEN ; print "-content_layers :";print RESET;print" [21] \nThe layers for content constraint. You can use comma-separated values. \n";
print GREEN ; print "-content_weight :";print RESET;print" [2e1] \nThe weight for content constraint. Increasing this value will make the result more content faithful. Decreasing the value will make the method more style faithful. Notice this value should be increase (for example, doubled) if layer 12 is included for MRF constraint. \n";
print GREEN ; print "-tv_weight :";print RESET;print" [1e-3] \nTV smoothness weight \n";
print GREEN ; print "-scaler :";print RESET;print" [2] \nRelative expansion from example to result. This settings is relevant only for syn setting.\n\n"; 

print GREEN ; print "-gpu_chunck_size_1 :";print RESET;print" [256] \nSize of chunks to split feature maps along the channel dimension. This is to save memory when normalizing the matching score in mrf layers. Use large value if you have large gpu memory. As reference we use 256 for Titan X, and 32 for Geforce GT750M 2G.\n";
print GREEN ; print "-gpu_chunck_size_2 :";print RESET;print" [16] \nSize of chuncks to split feature maps along the y dimension. This is to save memory when normalizing the matching score in mrf layers. Use large value if you have large gpu memory. As reference we use 16 for Titan X, and 2 for Geforce GT750M 2G. \n\n";

print "fixed parameters\n";
print GREEN ; print "-target_step_rotation :";print RESET;print" math.pi/24 \n";
print GREEN ; print "-target_step_scale :";print RESET;print" 1.05 \n";
print GREEN ; print "-output_folder :";print RESET;print" data/result/trans/MRF/ \n";
print GREEN ; print "-proto_file :";print RESET;print" /home/luluf/CNNMRF/data/models/VGG_ILSVRC_19_layers_deploy.prototxt\n"; 
print GREEN ; print "-model_file :";print RESET;print" /home/luluf/CNNMRF/data/models/VGG_ILSVRC_19_layers.caffemodel \n";
print GREEN ; print "-gpu :";print RESET;print" 0 Zero-indexed ID of the GPU to use \n";
print GREEN ; print "-nCorrection :";print RESET;print" 25 \n";
print GREEN ; print "-print_iter :";print RESET;print" 10 \n";
print GREEN ; print "-save_iter :";print RESET;print" 10 \n\n";
exit;
}

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
open (AUTOCONF,">","cnnmrf_auto.conf");
print AUTOCONF confstr(PROJECT);
print AUTOCONF confstr(FSTART);
print AUTOCONF confstr(FEND);
print AUTOCONF confstr(FSTEP);
print AUTOCONF confstr(SHOT);
print AUTOCONF confstr(CONTENTDIR);
print AUTOCONF confstr(CONTENT);
print AUTOCONF confstr(IN_USE_SHOT);
print AUTOCONF confstr(DOEDGES);
print AUTOCONF confstr(EDGEDIR);
print AUTOCONF confstr(EDGES);
print AUTOCONF confstr(EDGEDILATE);
print AUTOCONF confstr(EDGESMOOTH);
print AUTOCONF confstr(EDGESOPACITY);
print AUTOCONF confstr(EDGESMODE);
print AUTOCONF confstr(EDGESINVERT);
print AUTOCONF confstr(STYLEDIR);
print AUTOCONF confstr(STYLE);
print AUTOCONF confstr(STYLESCALE);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXTIN);
print AUTOCONF confstr(EXTOUT);
print AUTOCONF confstr(EXTEDGES);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF confstr(SIZE);
print AUTOCONF "\n#network\n";
print AUTOCONF confstr(NORMALIZE_GRADIENT);
print AUTOCONF confstr(POOLING);
print AUTOCONF confstr(OPTIMIZER);
print AUTOCONF confstr(INI_METHOD);
print AUTOCONF confstr(TYPE);
print AUTOCONF confstr(MODE);
print AUTOCONF "\n#hyperparameters\n";
print AUTOCONF confstr(MRFW);
print AUTOCONF confstr(CONTENTWEIGHT);
print AUTOCONF confstr(LEARNING_RATE);
print AUTOCONF confstr(MRFP);
print AUTOCONF confstr(NUMROT);
print AUTOCONF confstr(NUMSCALE);
print AUTOCONF confstr(MRFC);
print AUTOCONF "\n#\n";
print AUTOCONF confstr(NUMRES);
print AUTOCONF "if (\$NUMRES == 1)\n";
print AUTOCONF "\{\n";
print AUTOCONF confstr(NUMITER);
print AUTOCONF "\$MRFWEIGHT=\"\$MRFW\"\;\n";
print AUTOCONF "\$MRFPATCHSIZE=\"\$MRFP\"\;\n";
print AUTOCONF "\$MRFCONFIDENCE=\"\$MRFC\"\;\n";
print AUTOCONF "\$ITERS=\"\$NUMITER\"\;\n";
print AUTOCONF "\}\n";
print AUTOCONF "if (\$NUMRES == 2)\n";
print AUTOCONF "\{\n";
print AUTOCONF "\$NUMITER=\"$NUMITER,$NUMITER\"\;\n";
print AUTOCONF "\$MRFWEIGHT=\"\$MRFW,\$MRFW\"\;\n";
print AUTOCONF "\$MRFPATCHSIZE=\"\$MRFP,\$MRFP\"\;\n";
print AUTOCONF "\$MRFCONFIDENCE=\"\$MRFC,\$MRFC\"\;\n";
print AUTOCONF "\@tmp=split(/,/,\$NUMITER)\;\n";
print AUTOCONF "\$ITERS=\"\@tmp[0]\-\@tmp[1]\"\;\n";
print AUTOCONF "\}\n";
print AUTOCONF "if (\$NUMRES == 3)\n";
print AUTOCONF "\{\n";
print AUTOCONF "\$NUMITER=\"$NUMITER,$NUMITER,$NUMITER\"\;\n";
print AUTOCONF "\$MRFWEIGHT=\"\$MRFW,\$MRFW,\$MRFW\"\;\n";
print AUTOCONF "\$MRFPATCHSIZE=\"\$MRFP,\$MRFP,\$MRFP\"\;\n";
print AUTOCONF "\$MRFCONFIDENCE=\"\$MRFC,\$MRFC,\$MRFC\"\;\n";
print AUTOCONF "\@tmp=split(/,/,\$NUMITER)\;\n";
print AUTOCONF "\$ITERS=\"\@tmp[0]\-\@tmp[1]\-\@tmp[2]\"\;\n";
print AUTOCONF "\}\n";
print AUTOCONF "\n#automatic\n";
print AUTOCONF confstr(TARGETSTRIDE);
print AUTOCONF confstr(SOURCESTRIDE);
print AUTOCONF confstr(CONTENTLAYER);
print AUTOCONF confstr(MRFLAYERS);
print AUTOCONF confstr(TVWEIGHT);
print AUTOCONF confstr(GPUCHUNK1);
print AUTOCONF confstr(GPUCHUNK2);
print AUTOCONF "\n#preprocess\n";
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
print AUTOCONF "#4 : ideepcolor\n";
print AUTOCONF "#5 : index color\n";
print AUTOCONF confstr(DOLOCALCONTRAST);
print AUTOCONF confstr(DOEQUALIZE);
print AUTOCONF confstr(EQUALIZELEVEL);
print AUTOCONF confstr(EQUALIZEMIN);
print AUTOCONF confstr(EQUALIZEMAX);
print AUTOCONF confstr(NOISETYPE);
print AUTOCONF confstr(NOISESTRENGTH);
print AUTOCONF confstr(NOISESCALE);
print AUTOCONF "#postprocess\n";
print AUTOCONF confstr(DOMEDIANFILTER);
print AUTOCONF confstr(MEDIANRADIUS);
print AUTOCONF confstr(MEDIANREPEAT);
print AUTOCONF "#more\n";
print AUTOCONF confstr(DEV);
print AUTOCONF confstr(KEEPLEVEL2);
print AUTOCONF confstr(KEEPCOLORTRANSFERT);
print AUTOCONF confstr(CLEAN);
print AUTOCONF confstr(CSV);
print AUTOCONF confstr(GPU);
print AUTOCONF "\$PARAMS=\"_mrfp\$MRFP\\_mrfw\$MRFW\\_cw\$CONTENTWEIGHT\\_ssc\$STYLESCALE\\_mrfc\$MRFC\\_rot\$NUMROT\\_scale\$NUMSCALE\\_iter\$ITERS\\_\$INI_METHOD\\_grad\$NORMALIZE_GRADIENT\\_\$POOLING\\_\$OPTIMIZER\"\;\n";
print AUTOCONF "\$PARAMS=\"_mrfp\$MRFP\\_ssc\$STYLESCALE\\_lr\$LEARNING_RATE\\_iter\$ITERS\"\;\n";
print AUTOCONF "1\n";
}

#arguments
if ($#ARGV == -1) {
	print "usage: $scriptname \n";
	print "-help\n";
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
    print "writing cnnmrf_auto.conf : mv cnnmrf_auto.conf cnnmrf.conf\n";
    autoconf();
    if (-e "$STYLEDIR") {print "$STYLEDIR already exists\n";}
    else {$cmd="mkdir $STYLEDIR";system $cmd;}
    exit;
    }
  if (@ARGV[$arg] eq "-help") 
    {
    printhelp();
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
    $LOG1=" > /var/tmp/styleswap_$GPU.log";
    $LOG2=" 2> /var/tmp/styleswap_$GPU.log";
    print "gpu id : $GPU\n";
    }
 if (@ARGV[$arg] eq "-verbose") 
    {
    $VERBOSE=1;
    $LOG1="";
    $LOG2="";
    print "verbose ...\n";
    }
  if (@ARGV[$arg] eq "-size") 
    {
    $SIZE=@ARGV[$arg+1];
    print "size : $RESIZE\n";
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
  $CPU=0;
  $GMIC="/shared/foss/gmic/src/gmic";
  $QLUA="/shared/foss/torch-multi/install/bin/qlua";
  $PROTO="/shared/foss/CNNMRF/data/models/VGG_ILSVRC_19_layers_deploy.prototxt";
  $IDEEPCOLOR="/usr/bin/python /shared/foss/ideepcolor/GlobalHistogramTransfer.py";
  $PROTOTXT="/shared/foss/ideepcolor/models/global_model/deploy_nodist.prototxt";
  $CAFFEMODEL="/shared/foss/ideepcolor/models/global_model/global_model.caffemodel";
  $GLOBPROTOTXT="/shared/foss/ideepcolor/models/global_model/global_stats.prototxt";
  $GLOBCAFFEMODEL="/shared/foss/ideepcolor/models/global_model/dummy.caffemodel";
  $COLOR_TRANSFER="/shared/foss/color_transfer/color_transfer.py";
  $HMAP="/shared/foss/hmap/hmap_c.py";
  $LINEARCOLORTRANSFERT="/shared/foss/Neural-Tools/linear-color-transfer.py";
  if ($DEV) {$CNNMRF="/shared/foss/CNNMRF/cnnmrf_dev.lua";}
  else      {$CNNMRF="/shared/foss/CNNMRF/cnnmrf.lua";}
  $MODEL="/shared/foss/CNNMRF/data/models/VGG_ILSVRC_19_layers.caffemodel";
  #if ($NORMALIZE_GRADIENT) {$MODEL="/shared/foss/CNNMRF/data/models/vgg_normalised.caffemodel";}
  #else                     {$MODEL="/shared/foss/CNNMRF/data/models/VGG_ILSVRC_19_layers.caffemodel";}
  $ENV{PYTHONPATH} = "/shared/foss/caffe/python:/shared/foss/ideepcolor/caffe_files:$ENV{'PYTHONPATH'}";
  verbose("PYTHONPATH : $ENV{'PYTHONPATH'}");
  }
if ($userName eq "dev18")	#
  {
  $CPU=0;
  $GMIC="/usr/bin/gmic";
  $QLUA="/shared/foss-18/torch/install/bin/qlua";
  $PROTO="/shared/foss-18/CNNMRF/data/models/VGG_ILSVRC_19_layers_deploy.prototxt";
  $IDEEPCOLOR="/usr/bin/python3 /shared/foss-18/ideepcolor/GlobalHistogramTransfer.py";
  $PROTOTXT="/shared/foss-18/ideepcolor/models/global_model/deploy_nodist.prototxt";
  $CAFFEMODEL="/shared/foss-18/ideepcolor/models/global_model/global_model.caffemodel";
  $GLOBPROTOTXT="/shared/foss-18/ideepcolor/models/global_model/global_stats.prototxt";
  $GLOBCAFFEMODEL="/shared/foss-18/ideepcolor/models/global_model/dummy.caffemodel";
  $COLOR_TRANSFER="/shared/foss-18/color_transfer/color_transfer.py";
  $HMAP="/shared/foss-18/hmap/hmap.py";
  $LINEARCOLORTRANSFERT="/shared/foss-18/Neural-Tools/linear-color-transfer.py";
  if ($DEV) {$CNNMRF="/shared/foss-18/CNNMRF/cnnmrf_dev.lua";}
  else      {$CNNMRF="/shared/foss-18/CNNMRF/cnnmrf.lua";}
  $MODEL="/shared/foss-18/CNNMRF/data/models/VGG_ILSVRC_19_layers.caffemodel";
  #if ($NORMALIZE_GRADIENT) {$MODEL="/shared/foss/CNNMRF/data/models/vgg_normalised.caffemodel";}
  #else                     {$MODEL="/shared/foss/CNNMRF/data/models/VGG_ILSVRC_19_layers.caffemodel";}
  $ENV{PYTHONPATH} = "/shared/foss-18/caffe/python:/shared/foss-18/ideepcolor/caffe_files:$ENV{'PYTHONPATH'}";
  $ENV{LD_LIBRARY_PATH} = "/shared/foss-18/caffe/build/lib:$ENV{'LD_LIBRARY_PATH'}";
  verbose("PYTHONPATH : $ENV{'PYTHONPATH'}");
  }
if ($userName eq "lulu")	#
  {
  $CPU=1;
  $GMIC="/usr/bin/gmic";
  $QLUA="/shared/foss/torch-multi/install/bin/qlua";
  $PROTO="/shared/foss/CNNMRF/data/models/VGG_ILSVRC_19_layers_deploy.prototxt";
  $IDEEPCOLOR="/usr/bin/python /shared/foss/ideepcolor/GlobalHistogramTransfer.py";
  $PROTOTXT="/shared/foss/ideepcolor/models/global_model/deploy_nodist.prototxt";
  $CAFFEMODEL="/shared/foss/ideepcolor/models/global_model/global_model.caffemodel";
  $GLOBPROTOTXT="/shared/foss/ideepcolor/models/global_model/global_stats.prototxt";
  $GLOBCAFFEMODEL="/shared/foss/ideepcolor/models/global_model/dummy.caffemodel";
  $COLOR_TRANSFER="/shared/foss/color_transfer/color_transfer.py";
  $HMAP="/shared/foss/hmap/hmap_c.py";
  $LINEARCOLORTRANSFERT="/shared/foss/Neural-Tools/linear-color-transfer.py";
  if ($DEV) {$CNNMRF="/shared/foss/CNNMRF/cnnmrf_dev.lua";}
  else      {$CNNMRF="/shared/foss/CNNMRF/cnnmrf.lua";}
  $MODEL="/shared/foss/CNNMRF/data/models/VGG_ILSVRC_19_layers.caffemodel";
  #if ($NORMALIZE_GRADIENT) {$MODEL="/shared/foss/CNNMRF/data/models/vgg_normalised.caffemodel";}
  #else                     {$MODEL="/shared/foss/CNNMRF/data/models/VGG_ILSVRC_19_layers.caffemodel";}
  $ENV{PYTHONPATH} = "/shared/foss/caffe-cpu/python:/shared/foss/ideepcolor/caffe_files:$ENV{'PYTHONPATH'}";
  verbose("PYTHONPATH : $ENV{'PYTHONPATH'}");
  }

sub csv {

#auto frames
if ($FSTART eq "auto" || $FEND eq "auto")
    {
    $AUTODIR="$CONTENTDIR/$SHOT";
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
    #auto parameters
    $keycount++;
    if ($keycount > $KEYFRAME) {last;}
    }
#get input elements ,if keyframe mode $ii = $FSTART
if ($IN_USE_SHOT)
    {
    $INCONTENT="$CONTENTDIR/$SHOT/$CONTENT.$ii.$EXTIN";
    $INEDGES  ="$EDGEDIR/$SHOT/$EDGES.$ii.$EXTEDGES";
    }
else
    {
    $INCONTENT="$CONTENTDIR/$CONTENT.$ii.$EXTIN";
    $INEDGES  ="$EDGEDIR/$EDGES.$ii.$EXTEDGES";
    }
#reinit $ii if keyframe mode was on
$ii=sprintf("%04d",$i);
#working dir
$WORKDIR="$OOUTDIR/w$ii\_$$";
$WCONTENT  ="$WORKDIR/preprocess.$EXTOUT";
$WCOLOR    ="$WORKDIR/colortransfert.$EXTOUT";
$WEDGES    ="$WORKDIR/edges.$EXTOUT";
$WNEURAL   ="$WORKDIR/neural.$EXTOUT";
#output
$FINALFRAME="$OOUTDIR/$CCONTENT\_$SSTYLE$PARAMS.$ii.$EXTOUT";
$LEVEL2="$OOUTDIR/$CCONTENT\_$SSTYLE$PARAMS\_level2.$ii.$EXTOUT";
$COLORT="$OOUTDIR/$CCONTENT\_$SSTYLE.$ii.$EXTOUT";

if (-e $FINALFRAME && !$FORCE)
   {print BOLD RED "frame $FINALFRAME exists ... skipping\n";print RESET;}
else
  {
  $touchcmd="touch $FINALFRAME";
  system $touchcmd;
  print BOLD BLUE ("\nframe : $ii\n");print RESET;
  if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
#preprocessing content --> $WCONTENT
  if ($EXTIN eq "exr") 
    {$GMIC0="-apply_gamma 2.2 -n 0,255";} else {$GMIC0="";}
  if ($CONTENTBLUR != 0) 
    {$GMIC1="-fx_sharp_abstract $CONTENTBLUR,10,0.5,0,0";} else {$GMIC1="";}
  if (($BRIGHTNESS != 0) || ($CONTRAST != 0) || ($GAMMA != 0) || ($SATURATION != 0)) 
    {$GMIC2="-fx_adjust_colors $BRIGHTNESS,$CONTRAST,$GAMMA,0,$SATURATION";} else {$GMIC2="";}
  if ($DOLOCALCONTRAST) 
    {$GMIC3="-fx_LCE[0] 80,0.5,1,1,0,0";} else {$GMIC3="";}
  if ($DOEQUALIZE) 
    {$GMIC4="-equalize $EQUALIZELEVEL,$EQUALIZEMIN,$EQUALIZEMAX";} else {$GMIC4="";}
  $cmd="$GMIC -i $INCONTENT $GMIC0 $GMIC1 -resize2dx $SIZE $GMIC2 $GMIC3 $GMIC4 -o $WCONTENT $LOG2";
  verbose($cmd);
  print("--------> preprocess content [sizex:$SIZE blur:$CONTENTBLUR b/c/g/s:$BRIGHTNESS/$CONTRAST/$GAMMA/$SATURATION lce:$DOLOCALCONTRAST equalize:$EQUALIZELEVEL/$EQUALIZEMIN/$EQUALIZEMAX]\n");
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
  $cmd="$QLUA $CNNMRF -gpu $GPU -learning_rate $LEARNING_RATE -optimizer $OPTIMIZER -pooling $POOLING -type $TYPE -backend cudnn -ini_method $INI_METHOD -mrf_confidence_threshold $MRFCONFIDENCE -num_res $NUMRES -num_iter $NUMITER -mrf_layers $MRFLAYERS -mrf_weight $MRFWEIGHT -content_layers $CONTENTLAYER -content_weight $CONTENTWEIGHT -content_name $WCOLOR -style_scale $STYLESCALE -style_name $STYLEDIR/$STYLE -max_size $SIZE -output_folder $WORKDIR -target_num_rotation $NUMROT -target_num_scale $NUMSCALE -model_file $MODEL -tv_weight $TVWEIGHT -mrf_patch_size $MRFPATCHSIZE -target_sample_stride $TARGETSTRIDE -source_sample_stride $SOURCESTRIDE $LOG2";
  if ($NORMALIZE_GRADIENT)
    {
    $cmd=$cmd." -normalize_gradients";
    }
  print("--------> cnnmrf [mrfp:$MRFPATCHSIZE lr:$LEARNING_RATE ssc:$STYLESCALE nrot:$NUMROT nscale:$NUMSCALE $OPTIMIZER\/$POOLING dev:$DEV]\n");
  verbose($cmd);
  #-----------------------------#
  ($s1,$m1,$h1)=localtime(time);
  #-----------------------------#
  system $cmd;
  #create finalframe
  #find result image name
  @tmp=split(/\,/,$NUMITER);
  $final="res_$NUMRES\_@tmp[$NUMRES-1].$EXTOUT";
  verbose("finalname : $final");
  $cmd="cp $WORKDIR/$final $FINALFRAME";
  verbose($cmd);
  system $cmd;
  #keep level2 first frame
  if ($KEEPLEVEL2)
    {
    $cmd="cp $WORKDIR/res_2_10.$EXTOUT $LEVEL2";
    verbose($cmd);
    system $cmd;
    }
  if ($KEEPCOLORTRANSFERT)
    {
    $cmd="cp $WCOLOR $COLORT";
    verbose($cmd);
    system $cmd;
    }
  if ($PRINT)
    {
    $val=sprintf("%.05f",${$KEYNAME});
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
  print BOLD YELLOW "Writing $FINALFRAME took $hlat:$mlat:$slat \n";print RESET;
  #-----------------------------#
  }
}
}#swap sub

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
      csv();
      }
    }
   }
else
  {
  csv();
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
