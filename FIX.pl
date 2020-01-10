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
  $GMIC="/usr/bin/gmic";
  $LINEARCOLORTRANSFERT="python3 /shared/foss-18/Neural-Tools/linear-color-transfer.py";
  $DEOLDIFY="python3 /shared/foss-18/DeOldify/ImageColorizer.py";
  }

#defaults
$CONTENTDIR="$CWD/originales";
$CONTENT="clint.jpg";
$STYLEDIR="$CWD/styles";
$STYLE="hadiehshafie_14.png";
$STYLESCALE="8e-1";
$OUTDIR="$CWD/results";
$OUTPUTSIZE=1280;
#operations
$DOCOLORIZATION=1;
$DEOLDIFYMODEL=0;
$DEOLDIFYRENDERFACTOR=35;
$DOLOCALCONTRAST=0;
$DOCOLORTRANSFERT=1;
$DOISOTROPIC=2;
#
$VERBOSE=1;
#
$CCONTENT="$CONTENTDIR/$CONTENT";
$SSTYLE="$STYLEDIR/$STYLE";

#create dierctories
if (!-e $OUTDIR)  {$cmd="mkdir $OUTDIR";system $cmd;}
$WORKDIR="$OUTDIR/w$$";
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
$OUTPUT="$OUTDIR/$CCCONTENT\_$SSSTYLE.png";

#copy content to $WORKDIR
$I=0;
$cmd="$GMIC $CCONTENT -resize2dx $OUTPUTSIZE,5 -o $WORKDIR/$I.png";
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
#deoldify
if ($DOLOCALCONTRAST) {
    $J=$I+1;
    $cmd="$GMIC $WORKDIR/$I.png -fx_LCE[0] 80,0.5,1,1,0,0 -o $WORKDIR/$J.png";
    verbose($cmd);
    system $cmd;
    $I++;
}
if ($DOCOLORTRANSFERT) {
    $J=$I+1;
    $cmd="$LINEARCOLORTRANSFERT --mode pca --target_image  $WORKDIR/$I.png --source_image $SSTYLE --output_image $WORKDIR/$J.png";
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
