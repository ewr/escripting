#---------------------------------------------------------------------
#  $Id: ObjGTK.pm,v 1.1.1.1 2001/07/13 19:37:26 eric Exp $
#
#  eThreads - revolutionizing forums... again.
#  Copyright (C) 1999-2000 Eric Richardson
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
#---------------------------------------------------------------------

package ObjGTK;

use Gtk;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw();

#--------------------#
# Some Documentation #
#--------------------#

=head1 NAME 

ObjGTK - A GTK-Perl Wrapper

=head1 SYNOPSIS

Coming.

=head1 DESCRIPTION

This module wraps GTK to ease development.

=cut

#-------------#
# Module Core #
#-------------#

=item C<start>

    $gui = ObjGTK->start();

=cut

sub start {
    my $class = shift;

    init Gtk;

    $class = bless ( { }, $class );

    return $class;	
}

#----------

sub go {
    Gtk->main;
}

#----------

sub create_window {
    my $class = shift;
    my %args = @_;

    $class->{$args{name}} = new Gtk::Window($args{type});
    $class->{$args{name}}->set_title($args{title});

    $class->{$args{name}}->set_default_size(@{$args{d_size}}) if (
        $args{d_size}
    );

    $class->{$args{name}}->signal_connect("destroy", $args{destroy}) if (
        $args{destroy}
    );

    # now the fun begins

    $class->build($class->{$args{name}},$args{contents});

}

#----------

sub build {
    my ($class,$parent,$ref) = @_;
    foreach my $child (@{$ref}) {
        my $target = "Gtk::$$child[1]";
        $parent->{$$child[0]} = new $target(@{$$child[2]});
        $parent->add($parent->{$$child[0]});
        $parent->{$$child[0]}->show;
    
        if ($$child[3]) {
            $class->build($parent->{$$child[0]},$$child[3]);
        }
    }
}

#----------

sub button_bar {
    my $class = shift;
    my $widget = shift;
    my @buttons = @_;
    
    foreach my $button (@buttons) {
        my $b = Gtk::Button->new($$button[0]);
        $b->signal_connect("clicked",$$button[1]) if ($$button[1]);
        $b->show;
        $widget->pack_start($b,0,0,0);
    }
}

#----------

sub menu {
    my $class = shift;
    my $widget = shift;
    my @items = @_;

    foreach my $item (@items) {
        my $i = Gtk::MenuItem->new($$item[0]);
        $i->signal_connect("activate",$$item[1],$$item[2]);
        $i->show;
        $widget->append($i);
    }
}

#----------

1;
