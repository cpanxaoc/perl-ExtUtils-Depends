#!/usr/bin/perl

# We require 5.6 for sanity in general, and for 'our' in particular.
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
	dist => {
		$^O eq 'MSWin32'
			? ()
			: (PREOP => 'pod2text lib/ExtUtils/Depends.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;'),
		COMPRESS => 'gzip -9v',
		SUFFIX => '.gz',
	},
	NAME => 'ExtUtils::Depends',
	VERSION_FROM => 'lib/ExtUtils/Depends.pm',
	PREREQ_PM => {
		'File::Spec' => 0,
		'Data::Dumper' => 0,
		'IO::File' => 0,
	},
	MIN_PERL_VERSION => 5.006, #for META.yml
	META_MERGE => {
		build_requires => {
			'Test::More' => 0,
		},
		resources => {
			repository => 'http://git.gnome.org/cgit/perl-ExtUtils-Depends',
		},
		keywords => ['XS', 'XS extensions', 'dependency'],
		no_index => {
			package => 'ExtUtils::MM',
		},
	},
	LICENSE => 'perl',
);

use Cwd;

sub MY::postamble
{
	# none of this rpm stuff is useful on win32, and actually it can cause
	# nmake to barf.
	return @_ if $^O eq 'MSWin32';

	my @dirs = qw{$(RPMS_DIR) $(RPMS_DIR)/BUILD $(RPMS_DIR)/RPMS 
		      $(RPMS_DIR)/SOURCES $(RPMS_DIR)/SPECS $(RPMS_DIR)/SRPMS};
	my $cwd = getcwd();

	chomp (my $date = `date +"%a %b %d %Y"`);

	my %subs = (
		'VERSION' => '$(VERSION)',
		'SOURCE' => '$(DISTNAME)-$(VERSION).tar.gz',
		'DATE'    => $date,
	);

	my $substitute = '$(PERL) -npe \''.join('; ', map {
			"s/\\\@$_\\\@/$subs{$_}/g";
		} keys %subs).'\'';

"
realclean ::
	-\$(RM_F) perl-\$(DISTNAME).spec

RPMS_DIR=\$(HOME)/rpms

\$(RPMS_DIR)/:
	-mkdir @dirs

SUBSTITUTE=$substitute

perl-\$(DISTNAME).spec :: perl-\$(DISTNAME).spec.in \$(VERSION_FROM) Makefile
	\$(SUBSTITUTE) \$< > \$@

dist-rpms :: Makefile dist perl-\$(DISTNAME).spec \$(RPMS_DIR)/
	cp \$(DISTNAME)-\$(VERSION).tar.gz \$(RPMS_DIR)/SOURCES/
	rpmbuild -ba --define \"_topdir \$(RPMS_DIR)\" perl-\$(DISTNAME).spec

dist-srpms :: Makefile dist perl-\$(DISTNAME).spec \$(RPMS_DIR)/
	cp \$(DISTNAME)-\$(VERSION).tar.gz \$(RPMS_DIR)/SOURCES/
	rpmbuild -bs --define \"_topdir \$(RPMS_DIR)\" perl-\$(DISTNAME).spec
"
}
