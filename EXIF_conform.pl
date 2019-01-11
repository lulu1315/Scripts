#!/usr/bin/perl

use Image::ExifTool qw(:Public);

if ($#ARGV == -1) {
	print "usage: EXIF_conform -i inputdir -r refdir -e imageextension [jpg] -s [simulatemode]\n";
	print "   conform exif maker/mode/focallength from one refdir to another\n";
	exit;
}

$EXT="jpg";
$SIMULATE=0;

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-i") 
    {
    $INDIR=@ARGV[$arg+1];
    print "checking directory $INDIR\n";
    }
  if (@ARGV[$arg] eq "-r") 
    {
    $REFDIR=@ARGV[$arg+1];
    print "reference directory $REFDIR\n";
    }
  if (@ARGV[$arg] eq "-e") 
    {
    $EXT=@ARGV[$arg+1];
    print "checking $EXT files\n";
    }
  if (@ARGV[$arg] eq "-s") 
    {
    $SIMULATE=1;
    print "simulation mode\n";
    }
  }

$exifTool = new Image::ExifTool;

@images=();

if ($EXT eq "jpg")
    {
    @images=`find $INDIR -maxdepth 1 | egrep -i \'[.]jpe?g$\'`;
    }
if ($EXT eq "png")
    {
    @images=`find $INDIR -maxdepth 1 | egrep -i \'[.]png$\'`;
    }
$count=$#images+1;
print "found $count images\n";

foreach $input_image (@images)
{
  chop $input_image;
  @tmp=split(/\//,$input_image);
  $fullimage=@tmp[$#tmp];
  #refimage
  $refimage="$REFDIR/$fullimage";
  #read refimage exif
  $exifTool = new Image::ExifTool;
  $success = $exifTool->ExtractInfo($refimage);
  $exifmake=$exifTool->GetValue('Make');
  $exifmodel=$exifTool->GetValue('Model');
  $exiffocal=$exifTool->GetValue('FocalLength');
  $cmd="/usr/bin/exiftool -FocalLength='$exiffocal' -Make='$exifmake' -Model='$exifmodel' -overwrite_original $input_image";
  if ($SIMULATE)
    {
    print "ref image : $fullimage $exifmake $exifmodel $exiffocal\n";
    }
  else {print "$cmd\n";system $cmd;}
}
