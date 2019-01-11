#!/usr/bin/perl

use Cwd;
use Env;
use Term::ANSIColor qw(:constants);
use Image::Magick;
#http://www.imagemagick.org/script/command-line-options.php
use Sys::Hostname;
$host = hostname;
print "hostname : $host\n";
$script = $0;
print BOLD BLUE "script : $script\n";print RESET;
@tmp=split(/\//,$script);
$scriptname=$tmp[$#tmp];
@tmp=split(/\./,$scriptname);
$SCRIPTNAME=$tmp[0];
$scriptname=lc $tmp[0];
$CWD=getcwd;
#get project name
@tmp=split(/\//,$CWD);
$PROJECT=$tmp[$#tmp];
print BOLD BLUE "project : $PROJECT\n";print RESET;

#defaults
$INDIR="$CWD/mangastyle";
$IN="ima";
$OUTDIR="$CWD/deflickr_v4";
$OUT="deflickr";
$ZEROPAD=1;
$EXT="png";
$EXTIN="\$EXT";
$EXTOUT="\$EXT";
$VERBOSE=0;
$RESX=1280;
$RESY=720;
$AMOUNT=1;
$BLOCKSIZE=9.6;
$DETAIL=.3;
$RANGE=3;

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
print AUTOCONF confstr(INDIR);
print AUTOCONF confstr(IN);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(OUT);
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(EXTIN);
print AUTOCONF confstr(EXTOUT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF confstr(RESX);
print AUTOCONF confstr(RESY);
print AUTOCONF confstr(AMOUNT);
print AUTOCONF confstr(BLOCKSIZE);
print AUTOCONF confstr(DETAIL);
print AUTOCONF confstr(RANGE);
print AUTOCONF "1\n";
}

if ($#ARGV == -1) {
	print "usage: $SCRIPTNAME.pl \n";
	print "-autoconf\n";
	print "-conf file.conf\n";
	print "-csv csvfile.csv\n";
	print "-idir dirin\n";
	print "-i imagein\n";
	print "-odir dirout\n";
	print "-o imageout\n";
	print "-e image ext (png)\n";
	print "-zeropad4\n";
	print "-d amount blocksize detail range\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-autoconf") 
    {
    print "writing $scriptname\_auto.conf --> mv $scriptname\_auto.conf $scriptname.conf\n";
    autoconf();
    exit;
    }
  if (@ARGV[$arg] eq "-conf") 
    {
    $CONF=@ARGV[$arg+1];
    print BOLD BLUE "configuration file : $CONF\n";print RESET;
    require $CONF;
    if (-e "$OUTDIR") {print "$OUTDIR already exists\n";}
    else {$cmd="mkdir $OUTDIR";system $cmd;}
    }
  if (@ARGV[$arg] eq "-csv") 
    {
    $CSVFILE=@ARGV[$arg+1];
    print "using csv file $CONF\n";
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
  if (@ARGV[$arg] eq "-zeropad4") 
    {
    $ZEROPAD=1;
    print "zeropad4 ...\n";
    }
  if (@ARGV[$arg] eq "-d") 
    {
    $AMOUNT=@ARGV[$arg+1];
    $BLOCKSIZE=@ARGV[$arg+2];
    $DETAIL=@ARGV[$arg+3];
    $RANGE=@ARGV[$arg+4];
    print "deflickr parameters : $AMOUNT $BLOCKSIZE $DETAIL $RANGE\n";
    }
}

open (CSV , "$CSVFILE");
#first pass : get first and last frame
$FSTART=999999;
$FEND=1;
while ($line=<CSV>)
    {
    chop $line;
    @line=split(/,/,$line);
    $shot=@line[0];
    $parameter1=@line[1];
    $parameter2=@line[2];
    $fstart=@line[3];
    $fend=@line[4];   
    $process=@line[6];
    $parameter3=@line[7];
    if ($process)
      {
      if ($fstart < $FSTART) {$FSTART=$fstart;}
      if ($fend > $FEND) {$FEND=$fend;}
      }
    }
close CSV;
print ("frame start/end : $FSTART/$FEND\n");
$NBFRAMES=$FEND-$FSTART+1;
print ("$NBFRAMES frames\n");
print ("Writing $OUTDIR\_auto.nk\n");

open (NUKE,">","$OUTDIR\_auto.nk");

print NUKE "Root {\n";
print NUKE "inputs 0\n";
print NUKE "frame $NBFRAMES\n";
print NUKE "first_frame $FSTART\n";
print NUKE "last_frame $FEND\n";
print NUKE "lock_range true\n";
print NUKE "fps 25\n";
print NUKE "format \"$RESX $RESY 0 0 $RESX $RESY 1 \"\n";
print NUKE "}\n";
    
open (CSV , "$CSVFILE");
while ($line=<CSV>)
    {
    chop $line;
#    print "$line\n";
    @line=split(/,/,$line);
    $shot=@line[0];
    $parameter1=@line[1];
    $parameter2=@line[2];
    $fstart=@line[3];
    $fend=@line[4];   
    $process=@line[6];
    $parameter3=@line[7];
    
    $SSTYLE=$parameter1;
    $SSTYLE=~ s/.jpg//;
    $SSTYLE=~ s/.jpeg//;
    $SSTYLE=~ s/.png//;
    $SSTYLE=~ s/\.//;
    $IIN="$INDIR/$shot/$IN\_$SSTYLE\_v4.####.$EXT";
    $OOUT="$OUTDIR/$OUT.####.$EXT";
    
    if ($process)
    {
print NUKE "Read {\n";
print NUKE "inputs 0\n";
print NUKE "file $IIN\n";
print NUKE "first $fstart\n";
print NUKE "last $fend\n";
print NUKE "name $shot\n";
print NUKE "}\n";
print NUKE "OFXuk.co.thefoundry.furnace.f_deflicker2_v403 {\n";
print NUKE "amount $AMOUNT\n";
print NUKE "blockSize $BLOCKSIZE\n";
print NUKE "scaleDown 0.5\n";
print NUKE "useMotion true\n";
print NUKE "vectorDetail $DETAIL\n";
print NUKE "range $RANGE\n";
print NUKE "cacheBreaker true\n";
print NUKE "name $shot\_deflickr\n";
print NUKE "}\n";
print NUKE "Write {\n";
print NUKE "file $OOUT\n";
print NUKE "file_type $EXT\n";
print NUKE "first $fstart\n";
print NUKE "last $fend\n";
print NUKE "use_limit true\n";
print NUKE "name $shot\_write\n";
print NUKE "}\n";
    }
    }
close NUKE;
