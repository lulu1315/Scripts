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

$LOG1=">/var/tmp/$scriptname.log";
$LOG2="2>/var/tmp/$scriptname.log";
#$SEPCONV="th /shared/foss/torch-sepconv/run.lua -model lf";
$SEPCONV="python3 /shared/foss-18/pytorch-sepconv/run.py --model lf";

$SIZE=400;
$INDIR="originales";
$IN="ima";
$OUTDIR="sepconv";
$MAXITER=3;

if ($#ARGV == -1) {
  print "usage: $scriptname \n";
      print "-f startframe endframe\n";
      print "-idir dirin\n";
      print "-i imagein\n";
      print "-odir dirout\n";
      print "-iter maxiter\n";
      print "-size xsize\n";
      exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
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
  if (@ARGV[$arg] eq "-iter")
    {
    $MAXITER=@ARGV[$arg+1];
    print "max iterations : $MAXITER\n";
    }
  if (@ARGV[$arg] eq "-size")
    {
    $SIZE=@ARGV[$arg+1];
    print "xsize : $SIZE\n";
    }
  }
  
if (!-e "$OUTDIR") {$cmd="mkdir $OUTDIR";system $cmd;}

for ($i = $FSTART ; $i < $FEND ; $i++)
{
$j=$i+1;
$ii=sprintf("%04d",$i);
$jj=sprintf("%04d",$j);
$iii=sprintf("%04d",$i-1);
$jjj=sprintf("%04d",$j-1);

print BOLD GREEN "\nimage $i\n";print RESET;
$cmd="gmic $INDIR/$IN.$ii.png -to_colormode 3 -resize2dx $SIZE,5 -o $OUTDIR/iter0.$iii.png";
print "$cmd\n";
system $cmd;
$cmd="gmic $INDIR/$IN.$jj.png -to_colormode 3 -resize2dx $SIZE,5 -o $OUTDIR/iter0.$jjj.png";
print "$cmd\n";
system $cmd;

for ($iter = 1 ; $iter <= $MAXITER ; $iter++)
    {
    $step=2**$iter;
    $start=($i-1)*$step;
    $end=$start+$step;
    print BOLD YELLOW "iteration : $iter\n";print RESET;
    print "generating keyframes : ";
    for ($ima = $start ; $ima<= $end ; $ima=$ima+2)
        {
        $previter=$iter-1;
        $previma=$ima/2;
        $pprevima=sprintf("%04d",$previma);
        $iima=sprintf("%04d",$ima);
        $cmd="cp $OUTDIR/iter$previter.$pprevima.png $OUTDIR/iter$iter.$iima.png";
        print "$ima ";
        #print "$cmd\n";
        system $cmd;
        }
        print "\n";
        print "sepconv : ";
    for ($ima = $start+1 ; $ima< $end ; $ima=$ima+2)
        {
        $previma=$ima-1;
        $nextima=$ima+1;
        $pprevima=sprintf("%04d",$previma);
        $nnextima=sprintf("%04d",$nextima);
        $iima=sprintf("%04d",$ima);
        $cmd="$SEPCONV --first $OUTDIR/iter$iter.$pprevima.png --second $OUTDIR/iter$iter.$nnextima.png --out $OUTDIR/iter$iter.$iima.png";
        print "$ima ";
        #print "$cmd\n";
        system $cmd;
        }
        print "\n";
    }
}
