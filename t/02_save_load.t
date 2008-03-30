#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 24;
use ExtUtils::Depends;

my $dep_info = ExtUtils::Depends->new ('DepTest');

my $inc = '-Iinclude -I/usr/local/include -W -Wall -Werror -ansi';
$dep_info->set_inc ($inc);

my $libs = '-L/usr/local/lib -lfoobar';
$dep_info->set_libs ($libs);

my %pm_mapping = ('DepTest.pm' => 'build/DepTest.pm',
                  'DepTest/Helper.pm' => 'build/DepTest/Helper.pm');
$dep_info->add_pm (%pm_mapping);

my @xs_files = qw(DepTestFoo.xs
                  DepTestBar.xs);
$dep_info->add_xs (@xs_files);

my @c_files = qw(dep-test-foo.c
                 dep-test-bar.c);
$dep_info->add_c (@c_files);

my @typemaps = qw(build/foo.typemap
                  build/bar.typemap);
$dep_info->add_typemaps (@typemaps);

my @installed_files = qw(dep.h
                         dep-private.h);
$dep_info->install (@installed_files);

$dep_info->save_config ('t/inc/DepTest/Install/Files.pm');

# --------------------------------------------------------------------------- #

my %vars = $dep_info->get_makefile_vars;
is_deeply ($vars{TYPEMAPS}, \@typemaps);
is ($vars{INC}, $inc);
is ($vars{LIBS}, $libs);

foreach my $pm (keys %pm_mapping) {
  like ($vars{PM}{$pm}, qr/\Q$pm_mapping{$pm}\E/);
}

ok (exists $vars{PM}{'t/inc/DepTest/Install/Files.pm'});

foreach my $file (@installed_files) {
  like ($vars{PM}{$file}, qr/\Q$file\E/);
}

foreach my $xs_file (@xs_files) {
  ok (exists $vars{XS}{$xs_file});
}

foreach my $file (@c_files, @xs_files) {
  (my $stem = $file) =~ s/\.(?:c|xs)\z//;
  like ($vars{OBJECT}, qr/\Q$stem\E/);
  like ($vars{clean}{FILES}, qr/\Q$stem\E/);
}

# --------------------------------------------------------------------------- #

use lib qw(t/inc);

my $info = ExtUtils::Depends::load ('DepTest');

my $install_part = qr|DepTest.Install|;
like ($info->{inc}, $install_part);
ok (-1 != index $info->{inc}, $inc);

isa_ok ($info->{typemaps}, 'ARRAY');

like ($info->{instpath}, $install_part);

is_deeply ($info->{deps}, []);

is ($info->{libs}, $libs);

# --------------------------------------------------------------------------- #

unlink 't/inc/DepTest/Install/Files.pm';
