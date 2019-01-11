#!/usr/bin/perl

use Image::ExifTool qw(:Public);


if ($#ARGV == -1) {
	print "usage: RESOLUTION_prepare -i inputdir\n";
	print "     : do AUTOGAMMA RESOLUTION_equalize 1024 and 2048\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-i") 
    {
    $INDIR=@ARGV[$arg+1];
    print "checking directory $INDIR\n";
    }
  }
    
#no $INDIR
if ($INDIR eq "") 
  {
  $INDIR = "images/";
  }

$INDIR =~ s/\///;
  
#copie noexifs
$cmd="mv $INDIR/noexif/* $INDIR";
print "$cmd\n";
system $cmd;
#AUTOGAMMA
$cmd="AUTOGAMMA.pl -i $INDIR";
print "$cmd\n";
system $cmd;
#RESOLUTION_equalize
$cmd="RESOLUTION_equalize.pl -i $INDIR\_autogamma -r 1024";
print "$cmd\n";
system $cmd;
$cmd="RESOLUTION_equalize.pl -i $INDIR\_autogamma -r 2048";
print "$cmd\n";
system $cmd;
