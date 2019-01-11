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
$SFM="COLMAP";
#$SFM="MVG";
$INDIR="COLMAP_originales/mvs";
#$INDIR="MVG_C3_AKAF_U";
#$JSON="sequential_P1/sfm_data_registered.bin";$JS="P1SFM";
#$JSON="sequential_P1/robust_registered.bin";$JS="P1ROBUST";
#$JSON="sequential_P0/sfm_data.bin";
#$JS="P0SFM";
$JSON="sequential_P0/robust.bin";
$JS="P0ROBUST";
$RES=0;	#resolution
$DECIMATE=0.5;
$SPURIOUS=20;
$DOTEXTURE=1;

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
open (AUTOCONF,">","mvs_auto.conf");
print AUTOCONF confstr(PROJECT);
print AUTOCONF confstr(SFM);
print AUTOCONF confstr(INDIR);
print AUTOCONF confstr(JSON);
print AUTOCONF confstr(JS);
print AUTOCONF confstr(RES);
print AUTOCONF confstr(DECIMATE);
print AUTOCONF confstr(SPURIOUS);
print AUTOCONF confstr(DOTEXTURE);
print AUTOCONF "1\n";
}

if ($#ARGV == -1) {
	print "usage: GOMVS.pl \n";
	print "-autoconf\n";
	print "-conf file.conf\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-autoconf") 
    {
    print "writing mvs_auto.conf : mv mvs_auto.conf mvs.conf\n";
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

if ($userName eq "dev")	#
  {
  $CCD="/home/dev/ownCloud/Vortex/ccd_db/sensor_width_camera_database_v2.txt";
  $MVGBIN = "/shared/foss/openMVG_Build/Linux-x86_64-RELEASE";
  $MVSBIN = "/shared/foss/openMVS_build/bin";
  }
  
if ($userName eq "luluf")	#
  {
  $CCD="/home/luluf/ownCloud/Vortex/ccd_db/sensor_width_camera_database_v2.txt";
  $MVGBIN = "/shared/Code/openMVG-build/Linux-x86_64-RELEASE";
  $MVSBIN = "/shared/Code/openMVS$MVSVERSION-build/bin";
  }
  
#-----------------------------#
($s1,$m1,$h1)=localtime(time);
#-----------------------------#

if ($SFM eq "MVG")
    {
    $MVSSCENE="scene_$JS\_R$RES.mvs";
    if ($INDIR =~ m/MVG/)
        {
        $OUTDIR = $INDIR;
        $OUTDIR =~ s/MVG/MVS/;
        }
    if (-e "$OUTDIR") {print "$OUTDIR already exists\n";}
    else {$cmd="mkdir $OUTDIR";system $cmd;}
    $cmd="$MVGBIN/openMVG_main_openMVG2openMVS -i ./$INDIR/$JSON -o $OUTDIR/$MVSSCENE -d $OUTDIR/undistorted_images";
    print "$cmd\n";
    system $cmd;
    }
    
if ($SFM eq "COLMAP")
    {
    $OUTDIR=$INDIR;
    $MVSSCENE="scene";
    }
    
$cmd="$MVSBIN/DensifyPointCloud --estimate-colors 1 --estimate-normals 1 --resolution-level $RES $OUTDIR/$MVSSCENE.mvs";
print "$cmd\n";
system $cmd;
$cmd="$MVSBIN/ReconstructMesh --remove-spurious $SPURIOUS $OUTDIR/$MVSSCENE\_dense.mvs";
print "$cmd\n";
system $cmd;
$cmd="$MVSBIN/RefineMesh --decimate $DECIMATE $OUTDIR/$MVSSCENE\_dense_mesh.mvs";
print "$cmd\n";
system $cmd;
if ($DOTEXTURE)
{
$cmd="$MVSBIN/TextureMesh --resolution-level $RES $OUTDIR/$MVSSCENE\_dense_mesh_refine.mvs";
print "$cmd\n";
system $cmd;
}
$cmd="mv *.log *.dmap $OUTDIR";
print "$cmd\n";
system $cmd;

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
