# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'
use lib qw(./lib ./blib/lib ./blib/arch);
#########################

use Test::More;
BEGIN { plan tests => 11 };
use_ok("JSON::PC");

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(ref(JSON::PC::parse('{}')), 'HASH',  'call sub : hash');
is(ref(JSON::PC::parse('[]')), 'ARRAY', 'call sub : array');
is(JSON::PC::convert({}), "{}", 'call sub : member');
is(JSON::PC::convert([]), "[]", 'call sub : array');

my $pc = new JSON::PC;
isa_ok($pc, "JSON::PC");

is(ref($pc->parse('{}')), 'HASH',  'hash');
is(ref($pc->parse('[]')), 'ARRAY', 'array');

is($pc->convert({}), "{}", 'member');
is($pc->convert([]), "[]", 'array');

ok($pc->parse(qq|//   \n ["a","b", /*  */ {},123, null, true, false ]|));


