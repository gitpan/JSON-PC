use 5.008;
use ExtUtils::MakeMaker;

print <<EOF;

## DEPRECATED #####################################################
# This module is too buggy and is not maintained.
# Please try to use JSON::XS which is faster than JSON::Syck and
# properly works.
#
# Additionally, JSON module now use JSON::XS as the backend module
# and if not available, it uses the pure Perl module JSON::PP.
# Theire interfaces are incompatible to old JSON module (ver 1.xx).
#
# See to the new JSON module (ver 2.xx).
###################################################################

EOF

WriteMakefile(
    NAME              => 'JSON::PC',
    VERSION_FROM      => 'lib/JSON/PC.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/JSON/PC.pm', # retrieve abstract from module
       AUTHOR         => 'Makama <makamaka[at]donzoko.net>') : ()),
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    OBJECT            => q/$(O_FILES)/,

);


