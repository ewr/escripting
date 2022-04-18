#------------------------------------------------------------------------
#           .               .    .        regenerate RealGold indexes and 
# ,-,-. ,-. | , ,-. ,-. ,-. |  ,-|          new stories from the database
# | | | ,-| |<  |-' | | | | |  | | 
# ' ' ' `-^ ' ` `-' `-| `-' `' `-^ 
#                    `'                                by eric richardson
#------------------------------------------------------------------------
#  $Id: core.pm,v 1.12 2000/09/19 12:43:23 eric Exp $
#
#  makegold: generate RealGold stories and indexes
#  Copyright (C) 2000 Eric Richardson
#
#       This program is free software; you can redistribute it and/or
#       modify it under the terms of the GNU General Public License
#       as published by the Free Software Foundation; either version 2
#       of the License, or (at your option) any later version.
#
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#       GNU General Public License for more details.
#
#       You should have received a copy of the GNU General Public License
#       along with this program; if not, write to the Free Software
#       Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  
#       02111-1307, USA.
#
#  This script looks in the RealGold stories database for new stories, 
#  and generates pages for the stories it finds.  It then also 
#  regenerates the indexes for each of the topics.
#
#------------------------------------------------------------------------

package eGold::core;

use strict;
use vars qw($db %cfg @ISA @EXPORT @EXPORT_OK @files %stored);

use Image::Magick;
use Storable;
use String::CRC32;
use DBI;
use Mail::Sendmail;
use File::Rsync;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(%cfg $db @files %stored);
@EXPORT_OK = qw();

#----------

=head1 NAME

eGold::core - eGold core functions

=head1 SYNOPSIS

my $result = $core->function(@args);?

=head1 DESCRIPTION

This package provides functions utilized by scripts in the eGold content
management system.

=cut

#-----------#
# Functions #
#-----------#

=item B<start>

    $core = eGold::core->start("script");

This function initializes this package, loads the configuration file 
into memory, and returns a blessed reference.

=cut

sub start {
    my $class = shift;

    # load the config file
    require "cfg.main";
    %cfg = &cfg::cfg;
    $cfg{script} = shift;

    $db = DBI->connect(
        "DBI:mysql:$cfg{db}{db}:$cfg{db}{host}",$cfg{db}{user},$cfg{db}{pass}
    );

    if (-e $cfg{cache}.$cfg{script}) {
        my $s_ref = retrieve($cfg{cache}.$cfg{script});
        %stored = %{$s_ref};
    } else {
        %stored = ();
    }

    return bless ( { }, $class );
}

#----------

=item B<save_memory>

    $core->save_memory;

Save stored memory to a file.

=cut

sub save_memory {
    my $class 	= shift;
    Storable::store(\%stored,$cfg{cache}.$cfg{script});
}

#----------

=item B<store>

    $core->store('key','value');

Add a key/value to the stored hash.

=cut

sub store {
    my $class = shift;
    $stored{$_[0]} = $_[1];
}

#----------

=item B<get_template>

    my $html = $core->get_template($fully_expanded_file);

Load a template file.  Feed get_template a fully expanded template name 
(story.locale.topic) and it'll try to load story.locale.topic.html, then 
story.locale.html, then story.html before failing.

=cut

sub get_template {
    my ($class,$template) = @_;

    $template =~ s!\.$!!;

    sub try_template {
        return unless (${$_[0]});
        if (!-e $cfg{template_dir}.${$_[0]}.".html") {
            ${$_[0]} =~ s!\.?[^\.]+$!!i;
            &try_template;
        }
    }

    &try_template(\$template);
    return unless ($template);

    open(FILE, $cfg{template_dir}.$template.".html") 
        or die "can't open template '".$cfg{template_dir}.$template.".html': $!\n";

    my $html;
    while (<FILE>) { $html .= $_; }
    return $html;
}

#----------

=item B<write_file>

    $core->write_file(
        name	=> "name",
        data	=> $data,
    );

Checksums the file and compares it to the stored value to see if the file has been 
altered before writing it.  Also compares the checksum with the checksum of $data 
to see if you're actually feeding it new data that it should upload.  

=cut

sub write_file {
    my $class 	= shift;
    my %args 	= @_;

    my $name = $class->clean_up($args{name});

    my ($dir) = $name =~ m!(.*)/[^/]+$!;

    if (-e $cfg{output_dir}.$name) {
        if ($class->different($name)) {
#			$class->email(
#				To		=> $cfg{admin_email},
#				Subject	=> "File Conflict",
#				Body	=> qq(),
#			);
            $name =~ s!\.shtml$!\.new\.shtml!;
        } else {
            return if (crc32($args{data}) == $stored{$name});
        }
    }

    warn "outfile being written: $name\n";

    $class->mkdir($dir);

    $stored{$name} = crc32($args{data});
    warn "stored crc: $stored{$name}\t$name\n";


    # this makes sure it gets rsync'ed later
    push @files, $cfg{output_dir}.$name;

    open (FILE, ">".$cfg{output_dir}.$name) 
        or die "Could not write '$name': $!\n";

    print FILE $args{data};
    close FILE;

}

#----------

=item B<email>

    $core->email(
        To		=> "whoever",
        Subject	=> "Whatever",
        Body	=> "hey",
    );

Send an email.

=cut

sub email {
    my $class = shift;

#	sendmail(
#		From	=> $cfg{admin_email},
#		@_,
#	);
}

#----------

=item B<clean_up>

    my $result = $core->clean_up($var);

Clean up a value, most likely for use as a filename.  

=cut

sub clean_up {
    my ($class) = shift;

    $_ = shift;
        s!\s!_!gi;
        s![^\w\d\./_-]!!gi;
    return $_;
}

#----------

=item B<different>

    if ($core->different("file")) {
        #do something
    } else { #whatever }

Compare the stored checksum of file with a newly computed checksum for file to 
see if someone else has edited it.

=cut

sub different {
    my ($class,$file) = @_;

    open (FILE, $cfg{output_dir}.$file);
        my $f_crc = crc32(*FILE);
    close FILE;

    ($stored{$file} == $f_crc) ? 0 : 1;
}

#----------

=item B<mkdir>

    $core->mkdir("my/sub/dir");

Create a directory and all parent directories which don't already exist.

=cut

sub mkdir {
    my $class = shift;
    my $dir = shift;

    return if (-d $cfg{output_dir}.$dir);

    my ($parent) = $dir =~ m!^(.*)/[^/]+$!;
    if (!-d $cfg{output_dir}.$parent && $parent) {
        $class->mkdir($parent);
    }

    mkdir $cfg{output_dir}.$dir,0755 or die "couldn't make $dir: $!\n";
}

#----------

=item B<thumbnail>

    $core->thumbnail(
        image	=> "img.jpg",
        thumb	=> "thumbnail.jpg",
        width	=> "max_width",
        height	=> "max_height",
    );

Take a full sized image file and generate a thumbnail out of it.

=cut

sub thumbnail {
    my $class = shift;
    my %args = @_;

    my $im = Image::Magick->new;
    $im->Read($cfg{output_dir}.$args{image});

    my ($x,$y) = $im->Get('width','height');
    
    if ($args{width} && ($args{width} < $x)) {
        my $percent = ($args{width} / $x);
        $x = sprintf("%1d",($x * $percent));
        $y = sprintf("%1d",($y * $percent));
    }

    if ($args{height} && ($args{height} < $y)) {
        my $percent = ($args{height} / $y);
        $x = sprintf("%1d",($x * $percent));
        $y = sprintf("%1d",($y * $percent));
    }

    $im->Resize(
        width	=> $x,
        height	=> $y,
    );

    if ($args{letterbox}) {
        my $foo = new Image::Magick;
        $foo->Set(
            size	=> $args{width}."x".$args{height}
        );
        $foo->ReadImage('xc:white');
        my ($off_x,$off_y) = ('0','0');
        $off_x = (($args{width}-$x)/2) if ($x < $args{width});
        $off_y = (($args{height}-$y)/2) if ($y < $args{height});

        warn "off_x: $off_x\toff_y: $off_y\n";

        $foo->Composite(
            image		=> $im,
            compose		=> 'over',
            geometry	=> "+".$off_x."+".$off_y,
        );

        $foo->Write($cfg{output_dir}.$args{thumb});
    } else {
        $im->Write($cfg{output_dir}.$args{thumb});
    }
    
    open (THUMB, $cfg{output_dir}.$args{thumb});
        my $t_crc = crc32(*THUMB);
    close THUMB;

    return if ($t_crc == $stored{$args{thumb}});
    $stored{$args{thumb}} = $t_crc;
}

#----------

=item B<upload>

    $core->upload(@files);

Upload the files found in @files.

=cut

sub upload {
    my $class = shift;
    my @files = @_;

    warn "uploading: @files\n";

    my $rsync = File::Rsync->new(
        rsh			=> "/usr/local/bin/ssh",
        perms		=> 1,
        links		=> 1,
        recursive	=> 1,
        dest		=> $cfg{rsync}{host}.":".$cfg{rsync}{dir},
        src			=> $cfg{output_dir},
    );

    $rsync->exec or die "couldn't rsync: ".$rsync->err."\n";

}

=head1 AUTHOR

Eric Richardson <eric@ericrichardson.com>

=head1 COPYRIGHT

Copyright (C) 2000 Eric Richardson

This program is licensed under the terms of the GNU General 
Public License.  

=cut

#-------------#
# Change Logs #
#-------------#

# $Log: core.pm,v $
# Revision 1.12  2000/09/19 12:43:23  eric
# * changed determination of publish state
# * added letterboxing code to core::thumbnail
#
# Revision 1.11  2000/09/17 11:05:42  eric
# * changed the way for determining published stories
# * finished more functionality in make_archives
#
# Revision 1.10  2000/09/15 12:12:24  eric
# * added random_thumb script for generating home page thumbnails
# * added thumbnail code to eGold::core
#
# Revision 1.9  2000/09/15 11:43:27  eric
# * changed todays_stories to just display last ten stories regardless
#   of day (not exactly truth in naming, but i'm lazy)
# * added make_archives script to generate archive pages
# * little fixes
#
# Revision 1.8  2000/09/13 22:46:36  eric
# * some fixes
# * made stored mem work again
#
# Revision 1.7  2000/09/11 09:38:43  eric
# * first working revision of todays_stories
# * updates to eGold::core
#
# Revision 1.6  2000/09/08 13:16:11  eric
# * moved upload function to eGold::core
#
# Revision 1.5  2000/09/08 12:34:34  eric
# * moved more functions over from make_gold to eGold::core
#
# Revision 1.4  2000/09/08 12:22:37  eric
# * added write_file, clean_up, different, and mkdir functions to package
#
# Revision 1.3  2000/09/08 11:32:01  eric
# * moved get_template into eGold::core
#
# Revision 1.2  2000/09/08 11:20:57  eric
# * it would be cool if there was a way to make ascii art out of valid
#   Perl.  Unfortunately, my ascii art doesn't compile.
# * fixed a little bug in where the package tag was placed in eGold::core
#
# Revision 1.1  2000/09/08 11:08:40  eric
# * small fixes
# * got rid of a couple warns
# * added start of core module and todays_stories script
#

#----------

1;
