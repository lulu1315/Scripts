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

$INDIR="$CWD/originales";
$OUTDIR="$CWD/superres";
$LEN=-1;

if ($#ARGV == -1) {
	print "usage: $scriptname.pl \n";
	print "-idir dirin\n";
	print "-odir dirout\n";
	print "-len length [-1=all]\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-idir") 
    {
    $INDIR=@ARGV[$arg+1];
    print "in dir : $INDIR\n";
    }
  if (@ARGV[$arg] eq "-odir") 
    {
    $OUTDIR=@ARGV[$arg+1];
    print "out dir : $OUTDIR\n";
    }
  if (@ARGV[$arg] eq "-len") 
    {
    $LEN=@ARGV[$arg+1];
    print "length : $LEN\n";
    }
}
    
$userName =  $ENV{'USER'}; 
if ($userName eq "dev18" || $userName eq "render")	#
  {
  $TECOGAN="python3 /shared/foss-18/TecoGAN/main.py --cudaID 0 --mode inference --checkpoint /shared/foss-18/TecoGAN/model/TecoGAN --output_ext png";
  }
  
if (-e "$OUTDIR") {print "directory $OUTDIR already exists ..";}
else {$cmd="mkdir $OUTDIR";system $cmd;}

$tecocmd="$TECOGAN --output_dir $OUTDIR --input_dir_LR $INDIR --input_dir_len $LEN --summary_dir $OUTDIR";
print "$tecocmd\n";
system $tecocmd;
