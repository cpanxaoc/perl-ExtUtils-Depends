#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use TestHelper;

use ExtUtils::Depends;

my $tmp_inc = temp_inc;

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

my $INC_FRAG = '-Ddistinctive';
map { make_fake($_) } qw(Fakenew Fakeold);
sub Fakenew::Install::Files::Inline { +{ INC => $INC_FRAG } }
sub Fakenew::Install::Files::deps { qw(Fakeold) }
{
  no warnings 'once';
  @Fakeold::Install::Files::deps = qw(Fakenew);
  $Fakeold::Install::Files::inc = $INC_FRAG;
  $Fakeold::Install::Files::libs = '';
}
sub make_fake {
  my $class = shift . '::Install::Files';
  my @pieces = split '::', $class;
  require File::Spec;
  my $pm = join('/', @pieces) . '.pm';
  $INC{$pm} = File::Spec->catdir(qw(build fake), split '/', $pm);
}
sub test_load {
  my ($info, $msg) = @_;
  my $install_part = qr|Fake.*Install|;
  like ($info->{inc}, $install_part, "$msg inc generic");
  like ($info->{inc}, qr/$INC_FRAG/, "$msg inc specific");
  ok (scalar(grep { /Fake/ } @{$info->{deps}}), $msg);
  ok (exists $info->{libs}, $msg);
}
test_load (ExtUtils::Depends::load('Fakenew'), 'load new scheme');
test_load (ExtUtils::Depends::load('Fakeold'), 'load old scheme');

use Data::Dumper;
$Data::Dumper::Terse = 1;
$dep_info->save_config (catfile $tmp_inc, qw(DepTest Install Files.pm));

# --------------------------------------------------------------------------- #

my %vars = $dep_info->get_makefile_vars;
is_deeply ($vars{TYPEMAPS}, \@typemaps, 'makefile vars typemaps');
is ($vars{INC}, $inc, 'makefile vars inc');
is ($vars{LIBS}, $libs, 'makefile vars libs');

foreach my $pm (keys %pm_mapping) {
  like ($vars{PM}{$pm}, qr/\Q$pm_mapping{$pm}\E/, 'makefile vars PM');
}

ok (exists $vars{PM}{catfile $tmp_inc, qw(DepTest Install Files.pm)}, 'PM');

foreach my $file (@installed_files) {
  like ($vars{PM}{$file}, qr/\Q$file\E/, "PM $file");
}

foreach my $xs_file (@xs_files) {
  ok (exists $vars{XS}{$xs_file}, "XS $xs_file");
}

foreach my $file (@c_files, @xs_files) {
  (my $stem = $file) =~ s/\.(?:c|xs)\z//;
  like ($vars{OBJECT}, qr/\Q$stem\E/, "OBJECT $stem");
  like ($vars{clean}{FILES}, qr/\Q$stem\E/, "FILES $stem");
}

# --------------------------------------------------------------------------- #

my $info = ExtUtils::Depends::load ('DepTest');

my $install_part = qr|DepTest.Install|;
like ($info->{inc}, $install_part, "loaded inc");
isnt (index($info->{inc}, $inc), -1, "loaded inc content");

my @typemaps_expected = map { my $t = $_; $t =~ s#build/##; $t } @typemaps;
sub strip_typemap { my $t = $_; my $tmp = catfile('DepTest','Install',' '); $tmp =~ s# $##; $t =~ s#.*\Q$tmp\E##; $t }
is_deeply (
  [ map { strip_typemap($_) } @{$info->{typemaps}} ],
  \@typemaps_expected,
  'check typemaps actually saved/loaded'
);

like ($info->{instpath}, $install_part, 'instpath');

is_deeply ($info->{deps}, [], 'basic deps');

is ($info->{libs}, $libs, 'basic libs');

# now check package vars are set, per the ::load doc!
{
no warnings qw(once);
is ($DepTest::Install::Files::inc, $inc, 'package inc');
is_deeply (
  [ map { strip_typemap($_) } @DepTest::Install::Files::typemaps ],
  \@typemaps_expected,
  'package typemaps'
);
is_deeply (\@DepTest::Install::Files::deps, [], 'package deps');
is ($DepTest::Install::Files::libs, $libs, 'package libs');
}

# test Inline class methods
is_deeply (
  DepTest::Install::Files->Inline('C'),
  {
    INC => $inc,
    LIBS => $libs,
    TYPEMAPS => \@typemaps_expected,
  },
  'api check Inline method'
);
is_deeply ([ DepTest::Install::Files->deps ], [], 'api check deps method');

# --------------------------------------------------------------------------- #

done_testing;
