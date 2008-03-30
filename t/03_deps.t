#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 2;
use ExtUtils::Depends;

my $dep_info = ExtUtils::Depends->new ('DepTest');
$dep_info->save_config ('t/inc/DepTest/Install/Files.pm');

# --------------------------------------------------------------------------- #

use lib qw(t/inc);

my $info = ExtUtils::Depends->new ('UseTest', 'DepTest');

my %deps = $info->get_deps;
ok (exists $deps{DepTest});

# --------------------------------------------------------------------------- #

$info = ExtUtils::Depends->new ('UseTest');
$info->add_deps ('DepTest');
$info->load_deps;

%deps = $info->get_deps;
ok (exists $deps{DepTest});

# --------------------------------------------------------------------------- #

unlink 't/inc/DepTest/Install/Files.pm';
