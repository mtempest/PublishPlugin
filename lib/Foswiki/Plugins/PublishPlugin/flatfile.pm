#
# Copyright (C) 2012 Crawford Currie, http://c-dot.co.uk
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details, published at
# http://www.gnu.org/copyleft/gpl.html
#
# File writer module for PublishPlugin
#
package Foswiki::Plugins::PublishPlugin::flatfile;

use strict;

use Foswiki::Plugins::PublishPlugin::file;
our @ISA = ('Foswiki::Plugins::PublishPlugin::file');

sub new {
    my $class = shift;
    my $this  = $class->SUPER::new(@_);

    my $file = "$this->{path}$this->{params}->{outfile}";
    File::Path::mkpath($file);
    $file .= "/master.html";
    my $fh;
    if ( open( $fh, '>', $file ) ) {
        binmode($fh);
        push( @{ $this->{files} }, 'master.html' );
        $this->{flatfile} = $fh;
    }
    else {
        $this->{logger}->logError("Cannot write $file: $!");
    }
    return $this;
}

sub addString {
    my ( $this, $string, $file ) = @_;

    if ( $file !~ /\.html$/ ) {
        $this->SUPER::addString( $string, $file );
        return;
    }

    # It's an HTML file; nail it to the collection
    my $fh = $this->{flatfile};

    # Add an anchor to act as a destination for jumps to this topic
    print $fh "<!-- $file -->";
    my $a = _encodeAnchor($file);
    print $fh "<a name='$a'></a><h1>$file</h1>";
    print $fh $string;
}

sub addFile {
    my ( $this, $from, $to ) = @_;
    if ( $from !~ /\.html$/ ) {
        $this->SUPER::addFile( $from, $to );
        return;
    }
    my $fh;
    if ( open( $fh, '<', $from ) ) {
        local $/ = undef;
        my $data = <$fh>;
        close($fh);
        $this->addString( $data, $to );
    }
}

sub _encodeAnchor {
    my $a = shift;
    return $a if $a =~ /^[a-z][a-z0-9-_:.]$/i;
    $a =~ s/\.html$//;
    $a = "A$a" unless $a =~ /^[a-z]/i;
    $a =~ s/([^a-z0-9-_.])/':'.ord($1)/igex;
    return $a;
}

# Convert a topic URL to an anchor references
sub mapTopicURL {
    my ( $this, $path ) = @_;

    return '#' . _encodeAnchor($path);
}

sub close {
    my $this = shift;

    close( $this->{flatfile} ) if $this->{flatfile};
    return "$this->{params}->{outfile}/master.html";
}

1;

