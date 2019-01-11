#!/usr/bin/perl

use Cwd;
use Env;
use Term::ANSIColor qw(:constants);
use Image::Magick;
#http://www.imagemagick.org/script/command-line-options.php
use Sys::Hostname;
$host = hostname;
print "hostname : $host\n";
$CWD=getcwd;
#get project name
@tmp=split(/\//,$CWD);
$PROJECT=$tmp[$#tmp];
print "project : $PROJECT\n";

sub verbose {
    if ($VERBOSE) {print BOLD GREEN "@_\n";print RESET}
}

#defaults
$FSTART=1;
$FEND=100;
$FSTEP=2;
$FSTEPOUT=1;
$SHOT="";
$INDIR="$CWD";
$IN="originales/ima";
$IN_USE_SHOT=0;
$OUTDIR="$CWD";
$OUT="originales/ima_1of2";
$OUT_USE_SHOT=0;
$ZEROPAD=1;
$FORCE=0;
$EXT="png";
$VERBOSE=0;
$CSV=0;

if ($#ARGV == -1) {
	print "usage: SEQMODULO.pl \n";
	print "resample sequences by taking 1 pic out of M pics\n";
	print "-f startframe endframe [1,100]\n";
    print "-fstep step [2]\n";   
    print "-fstepout stepout [1]\n";   
    print "-fsartout frame start out [startframe]\n";   
	print "-idir dirin\n";
	print "-i imagein\n";
	print "-inshot : in use shot [0]\n";
	print "-odir dirout\n";
	print "-o imageout\n";
	print "-e image ext (png)\n";
	print "-csv csv_file.csv\n";
	print "-force\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-f") 
    {
    $FSTART=@ARGV[$arg+1];
    $FEND=@ARGV[$arg+2];
    print "seq : $FSTART $FEND\n";
    $FSTARTOUT=$FSTART;
    }
  if (@ARGV[$arg] eq "-fstep") 
    {
    $FSTEP=@ARGV[$arg+1];
    print "step : $FSTEP\n";
    }
  if (@ARGV[$arg] eq "-fstepout") 
    {
    $FSTEPOUT=@ARGV[$arg+1];
    print "step out : $FSTEPOUT\n";
    }
  if (@ARGV[$arg] eq "-fstartout") 
    {
    $FSTARTOUT=@ARGV[$arg+1];
    print "frame start out : $FSTARTOUT\n";
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
  if (@ARGV[$arg] eq "-e") 
    {
    $EXT=@ARGV[$arg+1];
    print "ext : $EXT\n";
    }
  if (@ARGV[$arg] eq "-csv") 
    {
    $CSVFILE=@ARGV[$arg+1];
    print "csv file : $CSVFILE\n";
    $CSV=1;
    $OUT_USE_SHOT=1;
    }
  if (@ARGV[$arg] eq "-force") 
    {
    $FORCE=1;
    print "force output ...\n";
    }
  if (@ARGV[$arg] eq "-inshot") 
    {
    $IN_USE_SHOT=1;
    print "in use shot ...\n";
    }
  }
  


if (-e "$OUTDIR") {print "$OUTDIR already exists\n";}
else {$cmd="mkdir $OUTDIR";print "$cmd\n";system $cmd;}
    
sub csv {

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
    
    $j=$FSTARTOUT;
    for ($i = $FSTART ;$i <= $FEND; $i = $i + $FSTEP)
    {
    $ii=sprintf("%04d",$i);
    $jj=sprintf("%04d",$j);
    if ($IN_USE_SHOT)
        {
        $IIN="$INDIR/$SHOT/$IN.$ii.$EXT";
        }
    else
        {
        $IIN="$INDIR/$IN.$ii.$EXT";
        }
    $OOUT="$OOUTDIR/$OUT.$jj.$EXT";

    if (-e $OOUT && !$FORCE)
        {print "frame $OOUT exists ... skipping\n";}
    else
        {
        $cmd="cp $IIN $OOUT";
        print "$cmd\n";
        system $cmd;
        }
    $j = $j + $FSTEPOUT;
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

