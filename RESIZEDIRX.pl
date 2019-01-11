#!/usr/bin/perl

use Image::Magick;

$FINALX=512;
$FINALY=$FINALX;

#arguments
if ($#ARGV == -1) {
	print "usage: RESIZEDIRX.pl -i inputdir -r resx\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-i") 
    {
    $INDIR=@ARGV[$arg+1];
    print "checking $INDIR\n";
    }
  if (@ARGV[$arg] eq "-r") 
    {
    $FINALX=@ARGV[$arg+1];
    print "final resolutionx $FINALX\n";
    }
}

$INDIR =~ s/\///;    
$OUTDIR="$INDIR\_$FINALX";
$cmd="mkdir $OUTDIR";
print "$cmd\n";
system $cmd;

@images=();
@images=`find $INDIR -maxdepth 1 | egrep -i \'[.]jpe?g$\'`;
#@images=`find $INDIR -maxdepth 1 | egrep -i \'[.]png$\'`;
$count=$#images+1;
print "found $count images\n";

$COUNT=0;

foreach $input_image (@images)
{
  $COUNT++;
  $CCOUNT=sprintf("ima.%04d.jpg",$COUNT);
  chop $input_image;
  @tmp=split(/\//,$input_image);
  $fullimage=@tmp[$#tmp];
  #get resolution
  $i = Image::Magick->new;
  $i->Read("$input_image");
  $resx = $i->[0]->Get('width');
  $resy = $i->[0]->Get('height');
  $cmd="gmic \"$input_image\" -resize2dx $FINALX -o $OUTDIR/$CCOUNT";
  print ("$cmd\n");
  system $cmd;
}
