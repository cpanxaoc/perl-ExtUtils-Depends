#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use TestHelper;

use ExtUtils::Depends;

my $tmp_inc = temp_inc;

plan (($^O eq 'MSWin32' || $^O eq 'cygwin') ?
        (tests => 1) :
        (skip_all => 'test only applicable to MSWin32 and cygwin'));

my $dep_info = ExtUtils::Depends->new ('DepTest');
$dep_info->save_config (catfile $tmp_inc, qw(DepTest Install Files.pm));

# --------------------------------------------------------------------------- #

my $use_info = ExtUtils::Depends->new ('UseTest', 'DepTest');
my %vars = $use_info->get_makefile_vars;

like ($vars{LIBS}, qr/DepTest/);

# --------------------------------------------------------------------------- #
