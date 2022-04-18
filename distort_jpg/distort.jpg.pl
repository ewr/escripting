#!/usr/bin/perl
#---------------------------------------------------------------------
#  $Id$
#
#  distort.jpg - the eWorld distortion cam
#  Copyright (C) 1999 Eric Richardson
#
#     This program is free software; you can redistribute it and/or
#     modify it under the terms of the GNU General Public License
#     as published by the Free Software Foundation; either version 2
#     of the License, or (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program; if not, write to the Free Software
#     Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
#     02111-1307, USA.
#
#     For information on distort.jpg, contact eScripting at
#     escripting@escripting.com , or check out the distort.jpg web 
#     site at http://www.escripting.com/distort.jpg/
#
#  This script takes a picture, does some distorting, and prints out 
#  jpg data.  It should be called like a regular image (ie. <img>).
#
#---------------------------------------------------------------------

use eModule;
%input = eModule->get_vars;

%cfg = (
	away_pics_dir	=> "/usr/local/web/eric/docs/images/away-messages",
	tmp_dir			=> "/tmp/eWorld-distortcam/",
);

$time = time;

# set up some temporary files
$tmp_ppm 	= $cfg{tmp_dir} 		. $time . ".ppm";
$tmp_jpg 	= $cfg{tmp_dir} 		. $time . ".jpg";
$tmp_ppm2 	= $cfg{tmp_dir}	. "2" 	. $time . ".ppm";
$tmp_ppm3 	= $cfg{tmp_dir} . "3" 	. $time . ".ppm";
$tmp_ppm4 	= $cfg{tmp_dir} . "4" 	. $time . ".ppm";

if (&status && !$input{away}) {
	# xscreensaver isn't active
	&get_random_colors;
	&take_picture;
	&load_distorts;
	&distort;
	&convert_to_jpg;
	&upload($tmp_jpg);
	&clean_up;
} else {
	# xscreensaver is active, so there's no one here 
	&load_away_pics;
}

#-------------#
# Subroutines #
#-------------#

sub status {
	my $output = `export DISPLAY=:0; xscreensaver-command -time 2>/dev/null`;
	if ($output =~ /non-blanked/) {
		return 1;
	} else {
		return 0;
	}
}

#----------

sub take_picture {
	my $output = `streamer -o $tmp_ppm 2>&1`;
	&take_picture if ($output =~ /Device or resource busy/);
}

#----------

sub clean_up {
	`rm $tmp_ppm $tmp_jpg $tmp_ppm2 $tmp_ppm3 $tmp_ppm4 2>/dev/null`;
}

#----------

sub load_away_pics {
	my $dir = $cfg{away_pics_dir};
	opendir(DIR, "$dir");
		my @away_pics = grep{/\.jpg$/} readdir(DIR);
	closedir DIR;

	my $num_away_pics = @away_pics;
	my $n = int(rand() * $num_away_pics);
	&upload("$dir/$away_pics[$n]");
}

#----------

sub get_random_colors {
	srand(time ^ $$);
	$colors = sprintf(
		"rgb:%02x/%02x/%02x-rgb:%02x/%02x/%02x",
		int(rand()*60),
		int(rand()*60),
		int(rand()*60),
		120+int(rand()*135),
		120+int(rand()*135),
		120+int(rand()*135)
	);
	return $colors;
}

#----------

sub distort {
	srand(time ^ $$);
	$n = int(rand() * 7);
	`$distorts{$n} > $tmp_ppm4 2>/dev/null` if ($distorts{$n});
}

#----------

sub convert_to_jpg {
	`convert $tmp_ppm4 $tmp_jpg 2>/dev/null`;
}

#----------

sub upload {
	my $img = shift;
	open (IMG, "$img") || die "doh. $!\n";
		while (<IMG>) { $image_data .= $_; }
	close (IMG) || die "couldn't close $image_jpg: $!\n";

	print "Last-Modified: " . format_http_time(time) . "\n";
	print "Expires: " . format_http_time(compute_expires_time($mod_time)) . "\n";
	print "Content-Type: image/jpeg\n";
	print "Content-Length: " . length($image_data) . "\n";
	print "\n";

	print $image_data;
	
}

#----------

sub compute_expires_time {
	my ($mod_time) = (@_);
	my $now = time;
	if ($mod_time < $now) { $mod_time = $now; }
	return $mod_time + $max_age;
}

#----------

sub format_http_time {
	my @time_fmt_days = ("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat");
	my @time_fmt_months = (
		"Jan", "Feb", "Mar", "Apr", "May", "Jun",
		"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
	);

	my ($time) = @_;
	my @t = gmtime($time);
	my ($sec, $min, $hour, $mday, $mon, $year, $wday) = @t;
	$year += 1900;
	$wday = $time_fmt_days[$wday];
	$mon = $time_fmt_months[$mon];
	return sprintf("%s, %02d %s %d %02d:%02d:%02d GMT",
		$wday, $mday, $mon, $year, $hour, $min, $sec);
}

#----------

sub load_distorts {
	my $w_h=`head -2 $tmp_ppm | tail -1`;
	($width,$height) = split(" ",$w_h);
	%distorts = (
		0	=> "ppmtopgm $tmp_ppm | pgmedge | pgmtoppm $colors | ppmnorm",
		1	=> "ppmtopgm $tmp_ppm | pgmenhance | pgmtoppm $colors",
		2	=> "ppmtopgm $tmp_ppm | pgmoil | pgmtoppm $colors",
		3	=> "ppmrelief $tmp_ppm | ppmtopgm | pgmedge | ppmrelief | ppmtopgm | pgmedge | pnminvert | pgmtoppm $colors",
		4	=> "ppmspread 71 $tmp_ppm > $tmp_ppm2; pnmarith -add $tmp_ppm $tmp_ppm2",
		5	=> "ppmpat -g2 $width $height | pnmdepth 255 > $tmp_ppm2;pnmarith -difference  $tmp_ppm $tmp_ppm2",
		6	=> "ppmpat -anticamo $width $height | pnmdepth 255 > $tmp_ppm2; pnmarith -difference $tmp_ppm $tmp_ppm2",
		7	=> "pgmnoise $width $height | pgmedge | pgmtoppm $colors > $tmp_ppm2;pnmarith -difference $tmp_ppm $tmp_ppm2 | pnmdepth 255 | pnmsmooth",
	);
}
