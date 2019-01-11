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
$INDIR="originales";
#sparse
$DOSPARSE=1;
$SIFTMAXIMAGESIZE=3096;
$CAMERAMODEL="SIMPLE_RADIAL";
$SINGLECAMERA=0;
#disto
$DODISTO=1;
$DENSEMAXIMAGESIZE=2048;
#mve conversion
$DOMVE=0;
#dense
$DODENSE=0;
#remesh
$DOPOISSON=0;
$POISSONTRIM=0;
#textures
$DOTEXTURE=0;
$KEEPUNSEEN="--keep_unseen_faces";
$VIEWSELECTION="--view_selection_model";
$OUTLIERREMOVAL="none";	
#Photometric outlier (pedestrians etc.) removal method: {none, gauss_damping, gauss_clamping}

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
open (AUTOCONF,">","colmap_auto.conf");
print AUTOCONF confstr(PROJECT);
print AUTOCONF confstr(INDIR);
print AUTOCONF confstr(DOSPARSE);
print AUTOCONF confstr(SIFTMAXIMAGESIZE);
print AUTOCONF confstr(CAMERAMODEL);
print AUTOCONF confstr(SINGLECAMERA);
print AUTOCONF confstr(DODISTO);
print AUTOCONF confstr(DENSEMAXIMAGESIZE);
print AUTOCONF confstr(DOMVE);
print AUTOCONF confstr(DODENSE);
print AUTOCONF confstr(DOPOISSON);
print AUTOCONF confstr(POISSONTRIM);
print AUTOCONF confstr(DOTEXTURE);
print AUTOCONF confstr(KEEPUNSEEN);
print AUTOCONF confstr(VIEWSELECTION);
print AUTOCONF confstr(OUTLIERREMOVAL);
print AUTOCONF "#Photometric outlier (pedestrians etc.) removal method: {none, gauss_damping, gauss_clamping}\n";
print AUTOCONF "1\n";
}

if ($#ARGV == -1) {
	print "usage: COLMAP.pl \n";
	print "-autoconf\n";
	print "-conf colmap.conf\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-autoconf") 
    {
    print "writing colmap_auto.conf\n";
    autoconf();
    exit;
    }
  if (@ARGV[$arg] eq "-conf") 
    {
    $CONF=@ARGV[$arg+1];
    print "using conf file $CONF\n";
    require $CONF;
    }
  }

$userName =  $ENV{'USER'}; 
if ($userName eq "lulu")	#a Nanterre
  {
  $COLMAPBIN="/mnt/shared/v14/colmap/build/src/exe";
  }
if ($userName eq "luluf")	#a Paris
  {
  $COLMAPBIN="~/colmap-3.1/build/src/exe";
  $TEXRECON="/shared/Code/mvs-texturing-write-obj-groups/build/apps/texrecon/texrecon";
  $MAKESCENE="/shared/Code/mve/apps/makescene/makescene";
  }
if ($userName eq "dev")	#a Paris
  {
  $COLMAPBIN="/shared/foss/colmap3.3/build/src/exe";
  $TEXRECON="/shared/foss/mvs-texturing/build/apps/texrecon/texrecon";
  $MAKESCENE="/shared/foss/mve/apps/makescene/makescene";
  }
  
$COLMAPDIR="COLMAP_$INDIR";

$cmd="mkdir $CWD/$COLMAPDIR";
print "$cmd\n";
system $cmd;

if ($DOSPARSE)
{
#
($s1,$m1,$h1)=localtime(time);
#
$cmd="$COLMAPBIN/feature_extractor --database_path $CWD/$COLMAPDIR/sift$SIFTMAXIMAGESIZE.db --image_path $CWD/$INDIR --SiftExtraction.max_image_size $SIFTMAXIMAGESIZE --ImageReader.camera_model $CAMERAMODEL --ImageReader.single_camera $SINGLECAMERA";
print "$cmd\n";
system $cmd;
#
$cmd="$COLMAPBIN/exhaustive_matcher --database_path $CWD/$COLMAPDIR/sift$SIFTMAXIMAGESIZE.db";
print "$cmd\n";
system $cmd;
#
$cmd="mkdir $CWD/$COLMAPDIR/sift$SIFTMAXIMAGESIZE";
print "$cmd\n";
system $cmd;
#
$cmd="$COLMAPBIN/mapper --database_path $CWD/$COLMAPDIR/sift$SIFTMAXIMAGESIZE.db --image_path $CWD/$INDIR --export_path $CWD/$COLMAPDIR/sift$SIFTMAXIMAGESIZE";
print "$cmd\n";
system $cmd;
#
#-----------------------------#
($s2,$m2,$h2)=localtime(time);
($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
print BOLD BLUE"\nsparse reconstruction generation took -> ";
print RESET;
print BOLD GREEN "$hlat:$mlat:$slat !\n \n";
print RESET;
}
if ($DODISTO)
{
#
($s1,$m1,$h1)=localtime(time);
#
$cmd="mkdir $CWD/$COLMAPDIR/dense$DENSEMAXIMAGESIZE";
print "$cmd\n";
system $cmd;
#
$cmd="$COLMAPBIN/image_undistorter --image_path $CWD/$INDIR --input_path $CWD/$COLMAPDIR/sift$SIFTMAXIMAGESIZE/0 --output_path $CWD/$COLMAPDIR/dense$DENSEMAXIMAGESIZE --output_type COLMAP --max_image_size $DENSEMAXIMAGESIZE";
print "$cmd\n";
system $cmd;
#convert to bundler workspace_format
$cmd="$COLMAPBIN/model_converter --input_path $CWD/$COLMAPDIR/dense$DENSEMAXIMAGESIZE/sparse/ --output_path $CWD/$COLMAPDIR/dense$DENSEMAXIMAGESIZE/sparse/sparse --output_type Bundler";
print "$cmd\n";
system $cmd;
$cmd="$COLMAPBIN/model_converter --input_path $CWD/$COLMAPDIR/dense$DENSEMAXIMAGESIZE/sparse/ --output_path $CWD/$COLMAPDIR/dense$DENSEMAXIMAGESIZE/sparse/sparse.ply --output_type PLY";
print "$cmd\n";
system $cmd;
#-----------------------------#
($s2,$m2,$h2)=localtime(time);
($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
print BOLD BLUE"\ndistorsion and bundler files generation took -> ";
print RESET;
print BOLD GREEN "$hlat:$mlat:$slat !\n \n";
print RESET;
}
if ($DOMVE)
{
#
($s1,$m1,$h1)=localtime(time);
#
#copy list to image for mve
$cmd="cp $CWD/$COLMAPDIR/dense$DENSEMAXIMAGESIZE/sparse/sparse.list.txt $CWD/$COLMAPDIR/dense$DENSEMAXIMAGESIZE/images/list.txt";
print "$cmd\n";
system $cmd;
$cmd="mkdir $CWD/$COLMAPDIR/dense$DENSEMAXIMAGESIZE/images/bundle";
print "$cmd\n";
system $cmd;
$cmd="cp $CWD/$COLMAPDIR/dense$DENSEMAXIMAGESIZE/sparse/sparse.bundle.out $CWD/$COLMAPDIR/dense$DENSEMAXIMAGESIZE/images/bundle/bundle.out";
print "$cmd\n";
system $cmd;
$cmd="$MAKESCENE $CWD/$COLMAPDIR/dense$DENSEMAXIMAGESIZE/images $CWD/$COLMAPDIR/mve";
print "$cmd\n";
system $cmd;
#-----------------------------#
($s2,$m2,$h2)=localtime(time);
($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
print BOLD BLUE"\nmve scene generation took -> ";
print RESET;
print BOLD GREEN "$hlat:$mlat:$slat !\n \n";
print RESET;
}
if ($DODENSE)
{
#
($s1,$m1,$h1)=localtime(time);
#
$cmd="$COLMAPBIN/dense_stereo --workspace_path $CWD/$COLMAPDIR/dense$DENSEMAXIMAGESIZE --workspace_format COLMAP --DenseStereo.max_image_size $DENSEMAXIMAGESIZE --DenseStereo.geom_consistency true";
print "$cmd\n";
system $cmd;
#
$cmd="$COLMAPBIN/dense_fuser --workspace_path $CWD/$COLMAPDIR/dense$DENSEMAXIMAGESIZE --workspace_format COLMAP --input_type geometric --output_path $CWD/$COLMAPDIR/dense$DENSEMAXIMAGESIZE/point-cloud.ply";
print "$cmd\n";
system $cmd;
#
#-----------------------------#
($s2,$m2,$h2)=localtime(time);
($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
print BOLD BLUE"\ndense cloud generation took -> ";
print RESET;
print BOLD GREEN "$hlat:$mlat:$slat !\n \n";
print RESET;
}
if ($DOPOISSON)
{
#
($s1,$m1,$h1)=localtime(time);
#
$cmd="$COLMAPBIN/dense_mesher --input_path $CWD/$COLMAPDIR/dense$DENSEMAXIMAGESIZE/point-cloud.ply --output_path $CWD/$COLMAPDIR/dense$DENSEMAXIMAGESIZE/mesh_poisson$POISSONTRIM.ply --DenseMeshing.trim $POISSONTRIM";
print "$cmd\n";
system $cmd;
#  
#-----------------------------#
($s2,$m2,$h2)=localtime(time);
($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
print BOLD BLUE"\npoisson mesh generation took -> ";
print RESET;
print BOLD GREEN "$hlat:$mlat:$slat !\n \n";
print RESET;
}
if ($DOTEXTURE)
{
#
($s1,$m1,$h1)=localtime(time);
#
$cmd="$TEXRECON -o $OUTLIERREMOVAL $VIEWSELECTION $KEEPUNSEEN $COLMAPDIR/mve::undistorted $COLMAPDIR/dense$DENSEMAXIMAGESIZE/mesh_poisson$POISSONTRIM.ply $COLMAPDIR/dense$DENSEMAXIMAGESIZE/mesh_poisson$POISSONTRIM\_textured";
print "$cmd\n";
system $cmd;
#-----------------------------#
($s2,$m2,$h2)=localtime(time);
($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
print BOLD BLUE"\ntexture generation took -> ";
print RESET;
print BOLD GREEN "$hlat:$mlat:$slat !\n \n";
print RESET;
#-----------------------------#
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
