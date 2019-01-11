#! /usr/bin/perl 
use Font::TTF::Font; 


foreach (@ARGV) { 
    $f = Font::TTF::Font->open($_) || die "Unable to open font file $_"; 
    $num = $f->{'maxp'}{'numGlyphs'}; 
    printf "%6d  %s\n", $num, $_; 
    $f->release; 
} 
