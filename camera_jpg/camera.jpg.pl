#!/usr/bin/perl
#---------------------------------------------------------------------
#  $Id$
#
#  camera.jpg - the eWorld camera
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
#     For information on camera.jpg, contact eScripting at
#     escripting@escripting.com , or check out the distort.jpg web 
#     site at http://www.escripting.com/camera.jpg/
#
#  This script takes a picture, converts it to jpg, and prints out 
#  jpg data.  It should be called like a regular image (ie. <img>).
#
#---------------------------------------------------------------------

use eModule;
%input = eModule->get_vars;

%cfg = (
	away_pics_dir	=> "/usr/local/web/eric/docs/images/away-messages",
	tmp_dir			=> "/tmp/eWorld-cam",
);

$time = time;
if (-e"$cfg{tmp_dir}/$time.ppm" || $input{size}) {
	do {
		$time -= 100;
	} until (!-e"$cfg{tmp_dir}/$time.ppm");
}

# set up some temporary files
`touch $cfg{tmp_dir}/$time.ppm`;
$tmp_ppm 	= "$cfg{tmp_dir}/$time.ppm";
$tmp_jpg 	= "$cfg{tmp_dir}/$time.jpg";

if (&status && !$input{away}) {
	# xscreensaver isn't active
	&take_picture;
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
	my $options = "-s $input{size}" if ($input{size});
	my $output = `streamer $options -o $tmp_ppm 2>&1`;
	&take_picture if ($output =~ /Device or resource busy/);
}

#----------

sub clean_up {
	`rm $tmp_ppm $tmp_jpg 2>/dev/null`;
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

sub convert_to_jpg {
	`convert $tmp_ppm $tmp_jpg 2>/dev/null`;
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
