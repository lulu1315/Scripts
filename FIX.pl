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

sub verbose {
    if ($VERBOSE) {print BOLD GREEN "@_\n";print RESET}
}

if ($userName eq "dev18") #
  {
  #$GMIC="/usr/bin/gmic";
  $GMIC="/shared/foss-18/gmic-2.8.3_pre/build/gmic";
  $LINEARCOLORTRANSFERT="python3 /shared/foss-18/Neural-Tools/linear-color-transfer.py";
  $DEOLDIFY="python3 /shared/foss-18/DeOldify/ImageColorizer.py";
  $LUA="/shared/foss-18/neural-style-jcj/neural_style.lua";
  if ($HOSTNAME =~ "s005" || $HOSTNAME =~ "s006") {$TH="/shared/foss-18/torch_GTX1080/install/bin/th";}
  if ($HOSTNAME =~ "s001" || $HOSTNAME =~ "s002" || $HOSTNAME =~ "s003") {$TH="/shared/foss-18/torch/install/bin/th";}
  $MODELDIR="/shared/foss-18/neural-style-jcj/models";
  }

#
$PROJECT="blondie2";$EXT="jpg";
$STYLE="aborigen2.jpg";
$STYLESCALE="8e-1";
$LOWDEFSIZE=512;
$OUTPUTSIZE=1800;
#global flags
$DOPREPROCESS=1;
$DOSTYLETRANSFER=1;
#preprocess flags
$DOCOLORIZATION=0;
$DOLOCALCONTRAST=1;
$DOEQUALIZE=0;
$DOCOLORCORRECT=0;
$DOCOLORTRANSFERT=1;
$DOTRANSFERTHISTOGRAM=1;
$DOISOTROPIC=2;
$DOSHARPABSTRACT=0;
$DONOISE=0;
#directories
$CONTENTDIR="$CWD/$PROJECT";
$CONTENT="$PROJECT.$EXT";
$STYLEDIR="$CWD/styles";
$OUTDIR="$CWD/$PROJECT";
#deoldify
$DEOLDIFYMODEL=0;
$DEOLDIFYRENDERFACTOR=35;
#equalize
$EQUALIZELEVELS=512;
$EQUALIZEMIN="10%";
$EQUALIZEMAX="90%";
#basic image modifications
$BRIGHTNESS=0;
$CONTRAST=0;
$GAMMA=0;
$SATURATION=0;
#manuelruder style transfer
#$NUMITERATIONS=600;
#$RECOLORITER=50;
#$TVWEIGHT="1e-4";
#$LEARNING_RATE="5e-1";
#$BETA1="9e-1";
#$EPSILON="1e-8";
#jcjohnson style transfer
$CONTENT_WEIGHT=1;
$STYLE_WEIGHT=2000;
$TV_WEIGHT="1e-6";
$STYLE_LAYER="relu1_1,relu2_1,relu3_1,relu4_1,relu5_1";
$CONTENT_LAYER="relu4_2";
$INIT="image"; #image or random
$SEED=-1;
#process
$NUMITERLOW=200;
$NUMITERHI=100;
$SAVEITER=5;
$PRINTITER=0;
#network
$OPTIMIZER="adam"; # adam lbfgs
$LEARNING_RATE="1";	#for adam optimisation
$POOLING="avg"; #max avg
$NORMALIZE_GRADIENT=1;
$MODEL="VGG19"; #VGG19N VGG19 FACE
#misc
$GPU=0;
$PARAMS="_ssc$STYLESCALE\_lr$LEARNING_RATE\_norm$NORMALIZE_GRADIENT\_iter$NUMITER";
#
$VERBOSE=1;
#
$CCONTENT="$CONTENTDIR/$CONTENT";
$SSTYLE="$STYLEDIR/$STYLE";

#create dierctories
if (!-e $OUTDIR)  {$cmd="mkdir $OUTDIR";system $cmd;}
$WORKDIR="$OUTDIR/work";
if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
  
#style
$SSSTYLE=$STYLE;
$SSSTYLE=~ s/.jpg//;
$SSSTYLE=~ s/.jpeg//;
$SSSTYLE=~ s/.png//;
$SSSTYLE=~ s/\.//;
#content
@tmp=split(/\./,$CONTENT);
$CCCONTENT=@tmp[0];
$FINALFRAME="$OUTDIR/$CCCONTENT\_$SSSTYLE$PARAMS.png";

if ($DOPREPROCESS) {
#copy content to $WORKDIR
$I=0;
$cmd="$GMIC $CCONTENT -resize2dx $OUTPUTSIZE,5 -c 0,255 -o $WORKDIR/$I.png";
verbose($cmd);
system $cmd;

#deoldify
if ($DOCOLORIZATION) {
    $J=$I+1;
    $cmd="$DEOLDIFY $DEOLDIFYMODEL $DEOLDIFYRENDERFACTOR $WORKDIR/$I.png $WORKDIR/$J.png";
    verbose($cmd);
    system $cmd;
    $I++;
}
if ($DOEQUALIZE) {
    $J=$I+1;
    $cmd="$GMIC $WORKDIR/$I.png -equalize $EQUALIZELEVELS,$EQUALIZEMIN,$EQUALIZEMAX -o $WORKDIR/$J.png";
    verbose($cmd);
    system $cmd;
    $I++;
}
#local contrast
if ($DOLOCALCONTRAST) {
    $J=$I+1;
    $cmd="$GMIC $WORKDIR/$I.png -fx_LCE[0] 80,0.5,1,1,0,0 -o $WORKDIR/$J.png";
    verbose($cmd);
    system $cmd;
    $I++;
}
#local contrast
if ($DOCOLORCORRECT) {
    $J=$I+1;
    $cmd="$GMIC $WORKDIR/$I.png -fx_adjust_colors $BRIGHTNESS,$CONTRAST,$GAMMA,0,$SATURATION -o $WORKDIR/$J.png";
    verbose($cmd);
    system $cmd;
    $I++;
}
if ($DOCOLORTRANSFERT) {
    $J=$I+1;
    $cmd="$GMIC $WORKDIR/$I.png $SSTYLE +transfer_pca[0] [1],ycbcr_y transfer_pca[-1] [1],ycbcr_cbcr -o[2] $WORKDIR/$J.png";
    verbose($cmd);
    system $cmd;
    $I++;
}
if ($DOTRANSFERTHISTOGRAM) {
    $J=$I+1;
    $cmd="$GMIC $WORKDIR/$I.png $SSTYLE -transfer_histogram[0] [1],512 -o[0] $WORKDIR/$J.png";
    verbose($cmd);
    system $cmd;
    $I++;
}
if ($DOISOTROPIC) {
    $J=$I+1;
    $cmd="$GMIC $WORKDIR/$I.png -fx_smooth_anisotropic 60,0.7,0.3,0.6,1.1,0.8,30,2,0,1,$DOISOTROPIC,0,0,50,50 -o $WORKDIR/$J.png";
    verbose($cmd);
    system $cmd;
    $I++;
}
if ($DOSHARPABSTRACT) {
    $J=$I+1;
    $cmd="$GMIC $WORKDIR/$I.png -fx_sharp_abstract $DOSHARPABSTRACT,10,0.5,0,0 -o $WORKDIR/$J.png";
    verbose($cmd);
    system $cmd;
    $I++;
}
if ($DONOISE) {
    $J=$I+1;
    $cmd="$GMIC $WORKDIR/$I.png -fx_simulate_grain 0,1,$DONOISE,100,0,0,0,0,0,0,0,0 -o $WORKDIR/$J.png";
    verbose($cmd);
    system $cmd;
    $I++;
}
#copy final preprocessed frame
$cmd="cp $WORKDIR/$J.png $WORKDIR/preprocess.png";
verbose($cmd);
system $cmd;
} #end $DOPREPROCESS

if ($DOSTYLETRANSFER) {
  #jcjohnson style transfer
  $jcjcmd="$TH $LUA -style_image $STYLEDIR/$STYLE -content_weight $CONTENT_WEIGHT -style_weight $STYLE_WEIGHT -gpu $GPU -print_iter $PRINTITER -save_iter $SAVEITER -optimizer $OPTIMIZER -pooling $POOLING -style_scale $STYLESCALE -tv_weight $TV_WEIGHT -seed $SEED -content_layers $CONTENT_LAYER -style_layers $STYLE_LAYER -init $INIT";
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
  #low def (512) output
  $finalcmd=$jcjcmd." -num_iterations $NUMITERLOW -content_image $WORKDIR/preprocess.png -image_size $LOWDEFSIZE -output_image $PROJECT/lowdef.png";
  verbose($finalcmd);
  system $finalcmd;
  #colortransfert
  $cmd="$GMIC $PROJECT/lowdef.png $SSTYLE +transfer_pca[0] [1],ycbcr_y transfer_pca[-1] [1],ycbcr_cbcr -o[2] $PROJECT/lowdef.png";
  verbose($cmd);
  system $cmd;
  #high def output
  $finalcmd=$jcjcmd." -num_iterations $NUMITERHI -content_image $PROJECT/lowdef.png -image_size $OUTPUTSIZE -output_image $FINALFRAME";
  #$jcjcmd=$jcjcmd." $LOG1";
  verbose($finalcmd);
  system $finalcmd;
  }
