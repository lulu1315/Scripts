#!/usr/bin/perl

#arguments
if ($#ARGV == -1) {
	print "usage: AUTOGAMMA.pl -i inputdir\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-i") 
    {
    $INDIR=@ARGV[$arg+1];
    print "checking $INDIR\n";
    }
}

$INDIR =~ s/\///;    
$OUTDIR="$INDIR\_autogamma";
$cmd="mkdir $OUTDIR";
print "$cmd\n";
system $cmd;

$MOGRIFY="convert";
$MOGRIFY_PARAMS="-auto-gamma";

@images=();
@images=`find $INDIR -maxdepth 1 | egrep -i \'[.]jpe?g$\'`;
$count=$#images+1;
print "found $count images\n";

foreach $input_image (@images)
{
  chop $input_image;
  @tmp=split(/\//,$input_image);
  $fullimage=@tmp[$#tmp];
  $cmd=sprintf("$MOGRIFY $input_image $MOGRIFY_PARAMS $OUTDIR/$fullimage");
  print ("$cmd\n");
  system $cmd;
  $cmd="exiftool -TagsFromFile $input_image -Make -Model -FocalLength -overwrite_original $OUTDIR/$fullimage";
  print "$cmd\n";
  system $cmd;
}
