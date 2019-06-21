#!/usr/bin/perl

use Image::ExifTool qw(:Public);


if ($#ARGV == -1) {
	print "usage: ROTATE.pl -i inputdir -r target_resolution\n";
	exit;
}

$TARGETRES=0;

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-i") 
    {
    $INDIR=@ARGV[$arg+1];
    print "checking directory $INDIR\n";
    }
  if (@ARGV[$arg] eq "-r") 
    {
    $TARGETRES=@ARGV[$arg+1];
    print "target_resolution = $TARGETRES\n";
    }
  }
    
#no $INDIR
if ($INDIR eq "") {print "use : -i inputdir to choose the current working dir\n";exit;}
#if ($TARGETRES==0) {print "please specify target resolution\n";exit;}

@images=`find $INDIR -maxdepth 1 | egrep -i \'[.]jpe?g$\'`;
$count=$#images+1;
print "found $count images\n";

$INDIR =~ s/\///;
$OUTDIR="$INDIR\_rotate";
print "outdir = $OUTDIR\n";
$cmd="mkdir $OUTDIR";
print "$cmd\n";
system $cmd;
  
foreach $input_image (@images)
  {
  chop $input_image;
  @tmp=split(/\//,$input_image);
  $fullimage=@tmp[$#tmp];
#identify resx and y
  $identify=`identify $input_image`;
  @tmp=split(/ /,$identify);
  @tmp1=split(/x/,@tmp[2]);
  $identifyx=@tmp1[0];
  $identifyy=@tmp1[1];
  
  if ($identifyx > $identifyy)
    {
    $maxpix=$identifyx;
    }
  else
    {
    $maxpix=$identifyy;
    }
  $scaleratio=100*$TARGETRES/$maxpix;
  print "$fullimage : $identifyx x $identifyy\n";
  $cmd="gmic -i $input_image -rotate -90 -o $OUTDIR/$fullimage";
  print "$cmd\n";
  system $cmd;
  }
