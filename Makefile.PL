use ExtUtils::MakeMaker;

WriteMakefile(
    'dist'	=> {
	            PREOP	=> 'pod2text lib/ExtUtils/Depends.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    'NAME'	=> 'ExtUtils::Depends',
    'VERSION_FROM' => 'lib/ExtUtils/Depends.pm',
);

package MY;
use Cwd;
sub postamble
{
	my @dirs = qw{rpms rpms/BUILD rpms/RPMS rpms/SOURCES
		      rpms/SPECS rpms/SRPMS};
	my $cwd = getcwd();

"
realclean ::
	-rm -f perl-\$(DISTNAME).spec

rpms/:
	-mkdir @dirs

perl-\$(DISTNAME).spec: perl-\$(DISTNAME).spec.in \$(VERSION_FROM) Makefile
	sed -e \"s/\@VERSION\@/\$(VERSION)/g\" -e \"s/\@SOURCE\@/\$(DISTNAME)-\$(VERSION).tar.gz/g\" \$< > \$@

dist-rpms: Makefile dist perl-\$(DISTNAME).spec rpms/
	cp \$(DISTNAME)-\$(VERSION).tar.gz rpms/SOURCES/
	rpmbuild -ba --define \"_topdir $cwd/rpms\" perl-\$(DISTNAME).spec
"
}
package MAIN;
