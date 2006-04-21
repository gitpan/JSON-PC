use Test::More;
use lib qw(./lib ./blib/lib ./blib/arch);
use strict;
#BEGIN { plan tests => 'no_plan' };
BEGIN { plan tests => 11 };
use JSON::PC;

my ($str,$obj);
my $pc = new JSON::PC;

$str = '/* test */ []';
$obj = $pc->parse($str);
is($pc->convert($obj),'[]');

$str = "// test\n []";
$obj = $pc->parse($str);
is($pc->convert($obj),'[]');

$str = '/* test ';
$obj = eval q|$pc->parse($str)|;
like($@, qr/Unterminated comment/, 'unterminated comment');

$str = '[]/* test */';
$obj = $pc->parse($str);
is($pc->convert($obj),'[]');

$str = "/* test */\n []";
$obj = $pc->parse($str);
is($pc->convert($obj),'[]');

$str = "// \n []";
$obj = $pc->parse($str);
is($pc->convert($obj),'[]');

$str = '{"ab": /* test */ "b"}';
$obj = $pc->parse($str);
is($pc->convert($obj),'{"ab":"b"}');

$str = "[  ]";
$obj = $pc->parse($str);
is($pc->convert($obj),'[]');

$str = "{  }";
$obj = $pc->parse($str);
is($pc->convert($obj),'{}');

$str = "// test \n [ /* test */ \n // \n 123 // abc\n ]";
$obj = $pc->parse($str);
is($pc->convert($obj),'[123]');


$str = "// \n [  ]";
$obj = $pc->parse($str);
is($pc->convert($obj),'[]');

