#!/usr/bin/perl

use Cwd;
use Env;
use Term::ANSIColor qw(:constants);
use Image::Magick;
#http://www.imagemagick.org/script/command-line-options.php
$CWD=getcwd;
#get project name
@tmp=split(/\//,$CWD);
$PROJECT=$tmp[$#tmp];
print "project : $PROJECT\n";

#defaults
$DRAW_KEYPOINTS=0;
$UNDISTORT_IMAGES=0;
$CAMERA_MODEL = 3; #default 3
$SFM_MODE="SEQ"; #SEQ GLOB
$GROUP=1;
$FEATURES_TYPE = "AKAZE_FLOAT"; # SIFT
$FEATURES_DENSITY = "ULTRA"; #HIGH
$NBTHREADS=32;
$MATCHMETHOD="AUTO"; #BRUTEFORCEL2 ANNL2 CASCADEHASHINGL2 FASTCASCADEHASHINGL2
#http://openmvg.readthedocs.io/en/latest/software/SfM/ComputeMatches/
$USE_PAIR=0;	#use explicit initial pairs
$PAIRA = "a.jpg";
$PAIRB = "b.jpg";
$INDIR="originales_1024";

sub autoconf {
open (AUTOCONF,">","mvg_auto.conf");
print AUTOCONF "\$PROJECT=\"$PROJECT\"\;\n";
print AUTOCONF "\$DRAW_KEYPOINTS=0\;\n";
print AUTOCONF "\$UNDISTORT_IMAGES=0\;\n";
print AUTOCONF "\$CAMERA_MODEL = 3\;\n"; #default 3
print AUTOCONF "\$SFM_MODE=\"SEQ\"\;\n"; #SEQ GLOB
print AUTOCONF "\$GROUP=1\;\n";
print AUTOCONF "\$NBTHREADS=32\;\n";
print AUTOCONF "\$FEATURES_TYPE = \"AKAZE_FLOAT\"\;\n"; # SIFT
print AUTOCONF "\$FEATURES_DENSITY = \"ULTRA\"\;\n"; #HIGH
print AUTOCONF "\$USE_PAIR=0\;\n";	#use explicit initial pairs
print AUTOCONF "\$PAIRA = \"a.jpg\"\;\n";
print AUTOCONF "\$PAIRB = \"b.jpg\"\;\n";
print AUTOCONF "\$INDIR=\"originales_1024\"\;\n";
print AUTOCONF "1\n";
close AUTOCONF;
}

if ($#ARGV == -1) {
	print "usage: GOMVG.pl \n";
	print "-autoconf\n";
	print "-conf file.conf\n";
	print "-i inputdir\n";
	print "-o outputdir\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-autoconf") 
    {
    print "writing auto.conf\n";
    autoconf();
    exit;
    }
  if (@ARGV[$arg] eq "-conf") 
    {
    $CONF=@ARGV[$arg+1];
    print "using conf file $CONF\n";
    require $CONF;
    }
  if (@ARGV[$arg] eq "-i") 
    {
    $INDIR=@ARGV[$arg+1];
    print "input images dir = $INDIR\n";
    }
  if (@ARGV[$arg] eq "-o") 
    {
    $OUTDIR=@ARGV[$arg+1];
    print "output mvg dir = $OUTDIR\n";
    }
  }
  
$userName =  $ENV{'USER'}; 

if ($userName eq "dev")	#
  {
  $CCD="/home/dev/ownCloud/Vortex/ccd_db/sensor_width_camera_database_v2.txt";
  $MVGBIN = "/shared/foss/openMVG_Build/Linux-x86_64-RELEASE";
  }
  
if ($userName eq "luluf")	#
  {
  $CCD="/home/luluf/ownCloud/Vortex/ccd_db/sensor_width_camera_database_v2.txt";
  $MVGBIN = "/shared/Code/openMVG-build/Linux-x86_64-RELEASE";
  }
  
if ($FEATURES_TYPE eq "AKAZE_FLOAT") {$FEAT="AKAF";}
if ($FEATURES_TYPE eq "AKAZE_MLDB") {$FEAT="AKAB";}
if ($FEATURES_TYPE eq "SIFT") {$FEAT="SIFT";}
if ($FEATURES_DENSITY eq "ULTRA") {$DENS="U";}
if ($FEATURES_DENSITY eq "HIGH") {$DENS="H";}
if ($FEATURES_DENSITY eq "NORMAL") {$DENS="N";}
$OUTDIR="MVG_C$CAMERA_MODEL\_$FEAT\_$DENS";
if (-e "$OUTDIR") {print "$OUTDIR already exists\n";}
else {$cmd="mkdir $OUTDIR";system $cmd;}
$MATCHDIR="$OUTDIR/matches";
if (-e "$MATCHDIR") {print "$MATCHDIR already exists\n";}
else {$cmd="mkdir $MATCHDIR";system $cmd;}

if ($SFM_MODE eq "SEQ")
  {
  $RECONDIR="$OUTDIR/sequential_P$USE_PAIR";
  if (-e "$RECONDIR") {print "$RECONDIR already exists\n";}
  else {$cmd="mkdir $RECONDIR";system $cmd;}
  }
else
  {
  $RECONDIR="$OUTDIR/global";
  if (-e "$RECONDIR") {print "$RECONDIR already exists\n";}
  else {$cmd="mkdir $RECONDIR";system $cmd;}
  }
if ($USE_PAIR == 2)
  {
  $cmd=("EXIF_check.pl -i $INDIR -movenoexif -moveinvalidcam");
  print "$cmd\n";
  system $cmd;
  $cmd=("rm $INDIR/sensor_width_camera_database.txt");
  print "$cmd\n";
  system $cmd;
  }
if ($USE_PAIR == 1)
  {
  $cmd=("mv $INDIR/noexif/* $INDIR");
  print "$cmd\n";
  system $cmd;
  }
  
#-----------------------------#
($s1,$m1,$h1)=localtime(time);
#-----------------------------#

print "1. Intrinsics analysis\n";
$cmd=("$MVGBIN/openMVG_main_SfMInit_ImageListing -i $INDIR -o $MATCHDIR -d $CCD -c $CAMERA_MODEL -g $GROUP");
print "$cmd\n";
system $cmd;

print "2. Compute features\n";
$cmd=("$MVGBIN/openMVG_main_ComputeFeatures -i $MATCHDIR/sfm_data.json -o $MATCHDIR -m $FEATURES_TYPE -p $FEATURES_DENSITY -n $NBTHREADS");
print "$cmd\n";
system $cmd;

if ($DRAW_KEYPOINTS)
  {
  $KEYPOINTS_DIR="$OUTDIR/keypoints";
  $cmd="mkdir $KEYPOINTS_DIR";
  print "$cmd\n";
  system $cmd;
  $cmd=("$MVGBIN/openMVG_main_exportKeypoints -i $MATCHDIR/sfm_data.json -d $MATCHDIR -o $KEYPOINTS_DIR");
  print "$cmd\n";
  system $cmd;
  }
  
print "3. Compute matches\n";
if ($SFM_MODE eq "SEQ")
  {
#  $cmd=("$MVGBIN/openMVG_main_ComputeMatches -i $MATCHDIR/sfm_data.json -o $MATCHDIR -n BRUTEFORCEL2 -r .8 -f 1");
  $cmd=("$MVGBIN/openMVG_main_ComputeMatches -i $MATCHDIR/sfm_data.json -o $MATCHDIR -n $MATCHMETHOD -r .8 -f 1");
  }
else
  {
  $cmd=("$MVGBIN/openMVG_main_ComputeMatches -i $MATCHDIR/sfm_data.json -o $MATCHDIR -f 1 -g e");	#global : essential matrix
  }
print "$cmd\n";
system $cmd;

print "4. Do Sequential/Incremental reconstruction\n";
if ($SFM_MODE eq "SEQ")
  {
  if ($USE_PAIR)
    {
    $cmd=("$MVGBIN/openMVG_main_IncrementalSfM -i $MATCHDIR/sfm_data.json -c $CAMERA_MODEL -m $MATCHDIR -o $RECONDIR -a $PAIRA -b $PAIRB");
    print "$cmd\n";
    system $cmd;
    }
  else
    {
    $cmd=("$MVGBIN/openMVG_main_IncrementalSfM -i $MATCHDIR/sfm_data.json -c $CAMERA_MODEL -m $MATCHDIR -o $RECONDIR");
    print "$cmd\n";
    system $cmd;
    }
  }
else	#global
  {
  $cmd=("$MVGBIN/openMVG_main_GlobalSfM -i $MATCHDIR/sfm_data.json -m $MATCHDIR -o $RECONDIR");
  print "$cmd\n";
  system $cmd;
  }
  
print "5. Colorize Structure\n";
$cmd=("$MVGBIN/openMVG_main_ComputeSfM_DataColor  -i $RECONDIR/sfm_data.bin -o $RECONDIR/colorized.ply");
print "$cmd\n";
system $cmd;

# optional, compute final valid structure from the known camera poses
print "6. Structure from Known Poses (robust triangulation)\n";
if ($SFM_MODE eq "SEQ")
  {
  $cmd=("$MVGBIN/openMVG_main_ComputeStructureFromKnownPoses -i $RECONDIR/sfm_data.bin -m $MATCHDIR -f $MATCHDIR/matches.f.bin -o $RECONDIR/robust.bin");
  print "$cmd\n";
  system $cmd;
  }
else
  {
  $cmd=("$MVGBIN/openMVG_main_ComputeStructureFromKnownPoses -i $RECONDIR/sfm_data.json -m $MATCHDIR -f $MATCHDIR/matches.e.bin -o $RECONDIR/robust.bin");
  print "$cmd\n";
  system $cmd;
  }

$cmd=("$MVGBIN/openMVG_main_ComputeSfM_DataColor -i $RECONDIR/robust.bin -o $RECONDIR/robust_colorized.ply");
print "$cmd\n";
system $cmd;

#clean unregistered images
if ($USE_PAIR)
  {
  $cmd=("JSON_unregistered.pl -i $RECONDIR/sfm_data.json -updatejson");
  print "$cmd\n";
  #system $cmd;
  $cmd=("JSON_unregistered.pl -i $RECONDIR/robust.json -moveimage -updatejson");
  print "$cmd\n";
  #system $cmd;
  }

if ($UNDISTORT_IMAGES)
  {
  $UNDISTORT_DIR="$OUTDIR/undistort";
  $cmd="mkdir $UNDISTORT_DIR";
  print "$cmd\n";
  system $cmd;
  if ($USE_PAIR)
    {
    $cmd="$MVGBIN/openMVG_main_ExportUndistortedImages -i $RECONDIR/sfm_data_registered.json -o $UNDISTORT_DIR";
    }
  else
    {
    $cmd="$MVGBIN/openMVG_main_ExportUndistortedImages -i $RECONDIR/sfm_data.bin -o $UNDISTORT_DIR";
    }
  print "$cmd\n";
  system $cmd;
  }
  
#-----------------------------#
($s2,$m2,$h2)=localtime(time);
($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
print BOLD BLUE"gomvg -> ";
print BOLD BLUE" took ";
print BOLD GREEN "$hlat:$mlat:$slat !\n \n";
print RESET;
#-----------------------------#
  
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
