#!/usr/bin/perl

#arguments
if ($#ARGV == -1) {
	print "usage: DUPES.pl -i inputdir\n";
	print "  remove duplicate pictures\n";
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
$OUTDIR="$INDIR/dupes";
$CHECKDIR="$INDIR/checkdupes";
$cmd="mkdir $OUTDIR";
print "$cmd\n";
system $cmd;
$cmd="mkdir $CHECKDIR";
print "$cmd\n";
system $cmd;

$cmd="findimagedupes $INDIR > $INDIR/dupes/dupes.txt";
print "$cmd\n";
system $cmd;

open (DUPES,"$INDIR/dupes/dupes.txt");
$count=1;
while ($line=<DUPES>)
    {
    chop $line;
    print "$line\n";
    @tmp=split(/ /,$line);
    $A=@tmp[0];
    $B=@tmp[1];
    @tmp=split(/\//,$A);
    $AA=@tmp[$#tmp];
    @tmp=split(/\//,$B);
    $BB=@tmp[$#tmp];
    @tmp=split(/_/,$AA);
    $AAA=@tmp[0];
    @tmp=split(/_/,$BB);
    $BBB=@tmp[0];
    $checkA="dupe$count.1.jpg";
    $checkB="dupe$count.2.jpg";
    $cmd="cp $A $CHECKDIR/$checkA\n";
    system $cmd;
    $cmd="cp $B $CHECKDIR/$checkB\n";
    system $cmd;
    if (int($AAA) > int($BBB))
      {
      $cmd="mv $B $OUTDIR\n";
      print "$cmd\n";
      system $cmd;
      }
    else
      {
      $cmd="mv $A $OUTDIR\n";
      print "$cmd\n";
      system $cmd;
      }
    $count++;
    }
close DUPES;
