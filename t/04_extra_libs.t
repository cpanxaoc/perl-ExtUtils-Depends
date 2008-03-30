#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use ExtUtils::Depends;

plan (($^O eq 'MSWin32' || $^O eq 'cygwin') ?
        (tests => 1) :
        (skip_all => 'test only applicable to MSWin32 and cygwin'));

my $dep_info = ExtUtils::Depends->new ('DepTest');
$dep_info->save_config ('t/inc/DepTest/Install/Files.pm');

# --------------------------------------------------------------------------- #

use lib qw(t/inc);

my $use_info = ExtUtils::Depends->new ('UseTest', 'DepTest');
my %vars = $use_info->get_makefile_vars;

like ($vars{LIBS}, qr/DepTest/);

# --------------------------------------------------------------------------- #

unlink 't/inc/DepTest/Install/Files.pm';
