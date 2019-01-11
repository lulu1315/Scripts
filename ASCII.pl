#!/usr/bin/perl

use Cwd;
use Env;
use Term::ANSIColor qw(:constants);
use Image::Magick;
#http://www.imagemagick.org/script/command-line-options.php
$script = $0;
print BOLD BLUE "script : $script\n";print RESET;
@tmp=split(/\//,$script);
$scriptname=$tmp[$#tmp];
@tmp=split(/\./,$scriptname);
$scriptname=lc $tmp[0];
print BOLD BLUE "scriptname : $scriptname\n";print RESET;
$CWD=getcwd;
#get project name
@tmp=split(/\//,$CWD);
$PROJECT=$tmp[$#tmp];
print BOLD BLUE "project : $PROJECT\n";print RESET;

#defaults
$FSTART=1;
$FEND=100;
$SHOT="";
$INDIR="$CWD/originales";
$IN="ima";
$IN_USE_SHOT=0;
$OUTDIR="$CWD/ascii";
$COLOR="color";
$LUMINANCE="luminance";
$PALETTE="palette";
$PALETTEFRAME="int(((\$FEND-\$FSTART)/2)+1)";
$ASCIIRESX=64;
$ASCIISYMBOLS=285;
$FINALRESX=1280;
$EQUALIZE=1;
$NORMALIZE=1;
$OUT_USE_SHOT=0;
$ZEROPAD=1;
$FORCE=0;
$EXT="png";
$EXTIN="\$EXT";
$EXTOUT="\$EXT";
$VERBOSE=0;
$CSV=0;
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
print AUTOCONF confstr(SHOT);
print AUTOCONF confstr(INDIR);
print AUTOCONF confstr(IN);
print AUTOCONF confstr(IN_USE_SHOT);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(COLOR);
print AUTOCONF confstr(LUMINANCE);
print AUTOCONF confstr(PALETTE);
print AUTOCONF confstr(PALETTEFRAME);
print AUTOCONF confstr(ASCIIRESX);
print AUTOCONF confstr(ASCIISYMBOLS);
print AUTOCONF confstr(FINALRESX);
print AUTOCONF confstr(EQUALIZE);
print AUTOCONF confstr(NORMALIZE);
print AUTOCONF confstr(OUT_USE_SHOT);
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF confstr(EXTIN);
print AUTOCONF confstr(EXTOUT);
print AUTOCONF "1\n";
close AUTOCONF;
}

if ($#ARGV == -1) {
	print "usage: $scriptname.pl \n";
	print "-autoconf\n";
	print "-conf file.conf\n";
	print "-f startframe endframe\n";
	print "-idir dirin\n";
	print "-i imagein\n";
	print "-odir dirout\n";
	print "-o imageout\n";
	print "-zeropad4 [1]\n";
	print "-force [0]\n";
	print "-verbose\n";
    print "-op\n";
    print "-csv csv_file.csv\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-autoconf") 
    {
    print "writing $scriptname\_auto.conf : mv $scriptname\_auto.conf $scriptname.conf\n";
    autoconf();
    exit;
    }
  if (@ARGV[$arg] eq "-conf") 
    {
    $CONF=@ARGV[$arg+1];
    print "using conf file $CONF\n";
    require $CONF;
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
 if (@ARGV[$arg] eq "-verbose") 
    {
    $VERBOSE=1;
    $LOG1="";
    $LOG2="";
    print "verbose on\n";
    }
  if (@ARGV[$arg] eq "-op") 
    {
    $OP=@ARGV[$arg+1];
    print "gmic op : $OP\n";
    }
  if (@ARGV[$arg] eq "-csv") 
    {
    $CSVFILE=@ARGV[$arg+1];
    print "csv file : $CSVFILE\n";
    $CSV=1;
    }
  }
  
$userName =  $ENV{'USER'}; 
if ($userName eq "lulu" || $userName eq "dev" || $userName eq "render")	#
  {
  $GMIC="/usr/bin/gmic";
  }
  
if ($VERBOSE) {$LOG1="";$LOG2="";}

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
    
# make palette
$pf=sprintf("%04d",$PALETTEFRAME);
$PALETTECOL="$OOUTDIR/$PALETTE\_color.$pf.$EXTIN";
$PALETTELUM="$OOUTDIR/$PALETTE\_luminance.$pf.$EXTIN";

if ($EQUALIZE) {$GMIC1="-equalize"} else {$GMIC1=""}
if ($NORMALIZE) {$GMIC2="-n 0,255"} else {$GMIC2=""}

$cmd="$GMIC $INDIR/$IN.$pf.$EXTIN $GMIC1 -resize2dx $ASCIIRESX,5 -colormap $ASCIISYMBOLS,1,1 -o $PALETTECOL $LOG2";
verbose($cmd);
print "--------------> color palette [equalize:$EQUALIZE nblevels:$ASCIISYMBOLS frame:$PALETTEFRAME]\n";
system $cmd;
$cmd="$GMIC $INDIR/$IN.$pf.$EXTIN -to_colormode 1 $GMIC1 $GMIC2 -resize2dx $ASCIIRESX,5 -colormap $ASCIISYMBOLS,1,1 -o $PALETTELUM $LOG2";
verbose($cmd);
print "--------------> luminance palette [equalize:$EQUALIZE normalize:$NORMALIZE nblevels:$ASCIISYMBOLS frame:$PALETTEFRAME]\n";
system $cmd;

for ($i = $FSTART ;$i <= $FEND;$i++)
{
#
$ii=sprintf("%04d",$i);
#
if ($IN_USE_SHOT)
    {
    $IIN="$INDIR/$SHOT/$IN.$ii.$EXTIN";
    }
else
    {
    $IIN="$INDIR/$IN.$ii.$EXTIN";
    }
    
if ($OUT_USE_SHOT)
    {
    $OOUTDIR="$OUTDIR/$SHOT";
    $COLOUT="$OOUTDIR/$COLOR.$ii.$EXTOUT";
    $LUMOUT="$OOUTDIR/$LUMINANCE.$ii.$EXTOUT";
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    }
else
    {
    $COLOUT="$OOUTDIR/$COLOR.$ii.$EXTOUT";
    $LUMOUT="$OOUTDIR/$LUMINANCE.$ii.$EXTOUT";
    }

if (-e $COLOUT && !$FORCE)
   {print BOLD RED "\nframe $COLOUT exists ... skipping\n";print RESET;}
else {
  #touch file
  $touchcmd="touch $COLOUT";
  #if ($VERBOSE) {print "$touchcmd\n";}
  verbose($touchcmd);
  system $touchcmd;
  #-----------------------------#
  ($s1,$m1,$h1)=localtime(time);
  #-----------------------------#
  $cmd="$GMIC -i $IIN $GMIC1 -resize2dx $ASCIIRESX,5 -i $PALETTECOL -index[0] [1],0,1 -keep[0] -resize2dx $FINALRESX,1 -o $COLOUT $LOG2";
  verbose($cmd);
  print "--------------> color [equalize:$EQUALIZE resx:$ASCIIRESX]\n";
  system $cmd;
  $cmd="$GMIC -i $IIN -to_colormode 1 $GMIC1 $GMIC2 -resize2dx $ASCIIRESX,5 -i $PALETTELUM -index[0] [1],0,1 -keep[0] -resize2dx 1280,1 -o $LUMOUT $LOG2";
  verbose($cmd);
  print "--------------> luminance [equalize:$EQUALIZE normalize:$NORMALIZE resx:$ASCIIRESX]\n";
  system $cmd;
  #-----------------------------#
  ($s2,$m2,$h2)=localtime(time);
  ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
  #print BOLD YELLOW "gmic : frame $ii took $hlat:$mlat:$slat \n\n";print RESET;
  #-----------------------------#
  #afanasy parsing format
  print BOLD YELLOW "Writing $COLOUT took $hlat:$mlat:$slat\n";print RESET;
  #print "\n";
  }
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
    $PALETTEFRAME=@line[1];
    $ASCIIRESX=@line[2];
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
  
#gestion des keyframes
sub keyframe {
    @keyvals = split(/,/,$_[0]);
    #print "keyvals = @keyvals\n";
    $key1=$keyvals[0];
    $key2=$keyvals[1];
    return $key1+$keycount*(($key2-$key1)/($KEYFRAME-1));
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
