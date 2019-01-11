#!/usr/bin/perl

use Cwd;
use Env;
use Term::ANSIColor qw(:constants);
use Image::Magick;
#http://www.imagemagick.org/script/command-line-options.php
$script = $0;
print BOLD BLUE "script : $script\n";print RESET;
@tmp=split(/\//,$script);
$scriptname=$tmp[$#tmp];
@tmp=split(/\./,$scriptname);
$scriptname=lc $tmp[0];
print BOLD BLUE "scriptname : $scriptname\n";print RESET;
$CWD=getcwd;
#get project name
@tmp=split(/\//,$CWD);
$PROJECT=$tmp[$#tmp];
print BOLD BLUE "project : $PROJECT\n";print RESET;

#defaults
$SIMSTART=1;
$FSTART=1;
$FEND=100;
$MOTIONVECTORS="flownet2/sequential/next";
$COLOR="originales/ima";
$COLORRESX=1280;
$COLORRESY=720;
$MOTIONRESX=1280;
$MOTIONRESY=720;
$TARGETEDGE=$COLORRESX/100;
$REGENERATIONDELAY=20;
$HIPREF="/shared/Scripts/hipref/advect_noise_16.hip";

sub verbose {
    if ($VERBOSE) {print BOLD GREEN "@_\n";print RESET}
}

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
open (AUTOCONF,">","$scriptname\_auto.conf");
print AUTOCONF confstr(PROJECT);
print AUTOCONF confstr(SIMSTART);
print AUTOCONF confstr(FSTART);
print AUTOCONF confstr(FEND);
print AUTOCONF confstr(MOTIONVECTORS);
print AUTOCONF confstr(COLOR);
print AUTOCONF confstr(COLORRESX);
print AUTOCONF confstr(COLORRESY);
print AUTOCONF confstr(MOTIONRESX);
print AUTOCONF confstr(MOTIONRESY);
print AUTOCONF confstr(TARGETEDGE);
print AUTOCONF confstr(REGENERATIONDELAY);
print AUTOCONF confstr(HIPREF);
print AUTOCONF "1\n";
}

if ($#ARGV == -1) {
	print "usage: $scriptname.pl \n";
	print "-autoconf\n";
	print "-conf file.conf\n";
	print "-f startframe endframe simstart\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-autoconf") 
    {
    print "writing $scriptname\_auto.conf : mv $scriptname\_auto.conf $scriptname.conf\n";
    autoconf();
    if (-e "$CWD/sims") {print "/sims already exists\n";}
    else {$cmd="mkdir $CWD/sims";system $cmd;}
    if (-e "$CWD/noise") {print "/noise already exists\n";}
    else {$cmd="mkdir $CWD/noise";system $cmd;}
    if (-e "$CWD/hou") {print "/hou already exists\n";}
    else {$cmd="mkdir $CWD/hou";system $cmd;}
    exit;
    }
  if (@ARGV[$arg] eq "-conf") 
    {
    $CONF=@ARGV[$arg+1];
    print "using conf file $CONF\n";
    require $CONF;
    }
  if (@ARGV[$arg] eq "-f") 
    {
    $FSTART=@ARGV[$arg+1];
    $FEND=@ARGV[$arg+2];
    $SIMSTART=@ARGV[$arg+3];
    print "seq : $FSTART $FEND simstart : $SIMSTART\n";
    }
}

$HSCRIPT = "/shared/apps/houdini/hfs16.0.557/bin/hscript";

print("--------> generating simulation [frame:$FSTART-$FEND simstart:$SIMSTART targetedge:$TARGETEDGE regenerationdelay:$REGENERATIONDELAY]\n");
$mkhipfile = "$CWD/hou/mkhip_$SIMSTART\_$FSTART\_$FEND.cmd";
$simulatefile = "$CWD/hou/simulate.cmd";
$houdinifile = "$CWD/hou/advect_$SIMSTART\_$FSTART\_$FEND.hip";

print("--------> writing mkhip file [$mkhipfile\n");
open (HSCRIPT , "> $mkhipfile");
print HSCRIPT "mread $HIPREF\n";
#print HSCRIPT "opparm /obj/CONTROLS ProjectRoot $CWD\n";
print HSCRIPT "opparm /obj/CONTROLS Project $PROJECT\n";
print HSCRIPT "opparm /obj/CONTROLS mvnext $MOTIONVECTORS\n";
print HSCRIPT "opparm /obj/CONTROLS color $COLOR\n";
print HSCRIPT "opparm /obj/CONTROLS simstartframe $SIMSTART\n";
print HSCRIPT "opparm /obj/CONTROLS shotframesx $FSTART\n";
print HSCRIPT "opparm /obj/CONTROLS shotframesy $FEND\n";
print HSCRIPT "opparm /obj/points targetedgelength $TARGETEDGE\n";
print HSCRIPT "opparm /obj/points regenerationdelay $REGENERATIONDELAY\n";
print HSCRIPT "opparm /obj/points colorresx $COLORRESX\n";
print HSCRIPT "opparm /obj/points colorresy $COLORRESY\n";
print HSCRIPT "opparm /obj/points motionresx $MOTIONRESX\n";
print HSCRIPT "opparm /obj/points motionresy $MOTIONRESY\n";
#init uvs !!!
print HSCRIPT "opparm -c /obj/points/UVREF initbbox\n";
print HSCRIPT "mwrite $houdinifile\n";
print HSCRIPT "q\n";
close HSCRIPT;

print("--------> generating hip file [$houdinifile\n");
$hcmd = "$HSCRIPT $mkhipfile";
print "$hcmd\n";
system $hcmd;

#print("--------> writing simulation cmd file [$simulatefile\n");
$STEP=100;
$COUNT=$FSTART;

while ($COUNT < $FEND)
    {
    $I=$COUNT;
    $J=$COUNT+$STEP-1;
    if ($J > $FEND) {$J = $FEND;}
    print("--------> bug loop[$I-$J]\n");
    open (SIMSCRIPT , "> $simulatefile");
    print SIMSCRIPT "mread $houdinifile\n";
    print SIMSCRIPT "opparm /obj/CONTROLS shotframesx $I\n";
    print SIMSCRIPT "opparm /obj/CONTROLS shotframesy $J\n";
    print SIMSCRIPT "opparm -c /obj/advectednoise/dopio1 execute\n";
    print SIMSCRIPT "memory\n";
    print SIMSCRIPT "q\n";
    close SIMSCRIPT;
    $hcmd = "$HSCRIPT $simulatefile";
    print "$hcmd\n";
    system $hcmd;
    $COUNT=$COUNT+$STEP;
    }



