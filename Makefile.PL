use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'File::OFind',
    AUTHOR              => q{David Weintraub <david@weintraub.name>},
    VERSION_FROM        => 'lib/File/OFind.pm',
    ABSTRACT_FROM       => 'lib/File/OFind.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'File-OFind-*' },
);
