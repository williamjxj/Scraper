#! /opt/lampp/bin/perl -w

use strict;
use warnings;
use Data::Dump qw(dump);
use DateTime;
use HTTP::Request;
my $request = HTTP::Request->new(
		GET => 'http://www.perl.org',
		);
$request->header( 'X-Perl' => '5.12.2' );
$request->header( 'Cat'    => 'Buster' );
my $data = {
	hash => {
		cat  => 'Buster',
		dog  => 'Addy',
		bird => 'Poppy',
		},
	array => [ qw( a b c ) ],
	datetime => DateTime->now,
	request  => $request,
	};
pp( $data ); # special void context mode
