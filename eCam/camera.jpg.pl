#!/usr/bin/perl
#-----------------------------------------------------------------------------
#       ___            _   _               ___         _      _   _
#  ___ / __|__ _ _ __ (_) | |__ _  _   ___/ __| __ _ _(_)_ __| |_(_)_ _  __ _
# / -_) (__/ _` | '  \ _  | '_ \ || | / -_)__ \/ _| '_| | '_ \  _| | ' \/ _` |
# \___|\___\__,_|_|_|_(_) |_.__/\_, | \___|___/\__|_| |_| .__/\__|_|_||_\__, |
#                               |__/                    |_|             |___/
#-----------------------------------------------------------------------------
#  $Id: camera.jpg,v 1.1.1.1 2000/06/10 19:09:24 eric Exp $
#
#  eCam - a smarter webcam
#  Copyright (C) 2000 Eric Richardson
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
#       For information, contact eScripting:
#           info@escripting.com
#           http://escripting.com
#
#  This script grabs the inputted host's newest picture out of the 
#  db, wraps a pre-expired expire time around it, and prints it out 
#  as an image.
#
#---------------------------------------------------------------------

use DBI;
%input = &get_vars;

my $db = DBI->connect("DBI:mysql:eCam:localhost","eCam","passwd");

my $get_ts = $db->prepare("
    select max(timestamp) from cams where host = ?
");

$get_ts->execute($input{host});

my $timestamp = $get_ts->fetchrow_array;

my $get_image = $db->prepare("
    select image from cams where host = ? and timestamp = ?
");

$get_image->execute($input{host},$timestamp);
my $img = $get_image->fetchrow_array;

print "Last-Modified: " . format_http_time(time) . "\n";
print "Expires: " . format_http_time(compute_expires_time($timestamp)) . "\n";
print "Content-Type: image/jpeg\n";
print "Content-Length: " . length($img) . "\n";
print "Pragma: no-cache\n";
print "\n";

print $img;

#----------

sub compute_expires_time {
    my $max_age = 10;
    my ($mod_time) = (@_);
    my $now = time;
    if ($mod_time < $now) { $mod_time = $now; }
    return ($mod_time - 86400);
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

sub get_vars {
    my ($info,%input);
    if ($ENV{'REQUEST_METHOD'} eq "POST") {
        read(STDIN,$info,$ENV{"CONTENT_LENGTH"});
    } else {
        $info=$ENV{QUERY_STRING};
    }

    foreach (split(/&/,$info)) {
        my ($var,$val) = split(/=/,$_,2);
        $var =~ s/\+/ /g;
        $val =~ s/\+/ /g;
        $val =~ s/%([0-9,A-F]{2})/sprintf("%c",hex($1))/ge;
        $input{$var} .= ", " if (defined($input{$var}));
        $input{$var} .= $val;
    }

    return %input;
}

#-------------#
# Change Logs #
#-------------#

# $Log: camera.jpg,v $
# Revision 1.1.1.1  2000/06/10 19:09:24  eric
# * first checkin of eCam
#

#---------------#
# End of Script #
#---------------#
