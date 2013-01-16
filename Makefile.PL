use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'UbuntuOne',
    AUTHOR              => q{Peco <peco@cpan.org>},
    VERSION_FROM        => 'lib/UbuntuOne.pm',
    ABSTRACT_FROM       => 'lib/UbuntuOne.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'UbuntuOne-*' },
);
