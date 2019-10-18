#!/usr/bin/perl

use Cwd;
use Env;
use Term::ANSIColor qw(:constants);
$HOSTNAME=`cat /etc/hostname`;chop $HOSTNAME;
$KDEVERSION=`lsb_release -c -s`;chop $KDEVERSION;
$GPUS=`nvidia-smi -L | wc -l`;chop $GPUS;
$GPUTYPE=`nvidia-smi -q -i 0 | grep "Product Name" | cut -d':' -f2 | cut -c 2-`;chop $GPUTYPE;
$script = $0;
@tmp=split(/\//,$script);
$scriptname=$tmp[$#tmp];
@tmp=split(/\./,$scriptname);
$scriptname=lc $tmp[0];
$CWD=getcwd;
#get project name
@tmp=split(/\//,$CWD);
$PROJECT=$tmp[$#tmp];
$userName =  $ENV{'USER'}; 
print BOLD BLUE "----------------------\n";print RESET;
print BOLD BLUE "user    : $userName\n";print RESET;
print BOLD BLUE "host    : $HOSTNAME\n";print RESET;
print BOLD BLUE "kde     : $KDEVERSION\n";print RESET;
print BOLD BLUE "gpu     : $GPUTYPE (x$GPUS)\n";print RESET;
print BOLD BLUE "script  : $scriptname\n";print RESET;
print BOLD BLUE "project : $PROJECT\n";print RESET;
print BOLD BLUE "----------------------\n";print RESET;

#defaults
$CSV=0;
$TEMPLATE="$CWD/hou/template.hip";
$SHOT="P0";
$FSTART=1;
$FEND=100;
$SUBMIT=0;

#arguments
if ($#ARGV == -1) {
	print "usage: $scriptname \n";
	print "-template template.hip\n";
    print "-f startframe endframe\n";
    print "-shot shot\n";
	print "-csv csv_file.csv\n";
	print "-submit (submit scene)\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-template") 
    {
    $TEMPLATE=@ARGV[$arg+1];
    print BOLD BLUE "template : $TEMPLATE\n";print RESET;
    }
  if (@ARGV[$arg] eq "-f") 
    {
    $FSTART=@ARGV[$arg+1];
    $FEND=@ARGV[$arg+2];
    print BOLD BLUE "seq : $FSTART $FEND\n";print RESET;
    }
  if (@ARGV[$arg] eq "-shot") 
    {
    $SHOT=@ARGV[$arg+1];
    print BOLD BLUE "shot : $SHOT\n";print RESET;
    }
  if (@ARGV[$arg] eq "-csv") 
    {
    $CSVFILE=@ARGV[$arg+1];
    $CSV=1;
    print BOLD BLUE "csv file : $CSVFILE\n";print RESET;
    }
  if (@ARGV[$arg] eq "-submit") 
    {
    $SUBMIT=1;
    print BOLD BLUE "submiting scenes\n";print RESET;
    }
}

$HSCRIPT="hscript-17.5.327";
$HOUDIR="$CWD/hou_auto";
if (-e "$HOUDIR") {print "$HOUDIR already exists\n";}
    else {$cmd="mkdir $HOUDIR";system $cmd;}
    
sub hou {
    #do houdini scene
    print BOLD GREEN "--> shot $SHOT [$FSTART,$FEND]\n";print RESET;
    #create hscript cmd
    $hscriptfile = "$HOUDIR/$SHOT.cmd";
    open (HSCRIPT , "> $hscriptfile");
    print HSCRIPT "mread $TEMPLATE\n";
    print HSCRIPT "opparm /obj/CONTROLS shot $SHOT\n";
    $TSTART=($FSTART-1)/24;
    $TEND=$FEND/24;
    print HSCRIPT "tset $TSTART $TEND\n";
    print HSCRIPT "frange $FSTART $FEND\n";
    print HSCRIPT "fcur $FSTART\n";
    print HSCRIPT "mwrite $HOUDIR/$SHOT.hip\n";
    print HSCRIPT "q\n";
    close HSCRIPT;
    $hcmd = "$HSCRIPT $hscriptfile";
    print "$hcmd\n";
    system $hcmd;
    #submit scene
    if ($SUBMIT)
        {
        #create hscript cmd
        $hscriptfile = "$HOUDIR/$SHOT\_submit.cmd";
        open (HSCRIPT , "> $hscriptfile");
        print HSCRIPT "mread $HOUDIR/$SHOT.hip\n";
        print HSCRIPT "opparm -c /obj/ropnet1/afanasy1 submit\n";
        print HSCRIPT "q\n";
        close HSCRIPT;
        $hcmd = "$HSCRIPT $hscriptfile";
        print "$hcmd\n";
        system $hcmd;
        }
    }

#main
if ($CSV)
  {
  open (CSV , "$CSVFILE");
  while ($line=<CSV>)
    {
    chop $line;
    @line=split(/,/,$line);
    $SHOT=@line[0];
    $FSTART=@line[3];
    $FEND=@line[4];
    $LENGTH=@line[5];   
    $process=@line[6];
    if ($process)
      {
      hou();
      }
    }
   }
else
  {
  hou();
  }
