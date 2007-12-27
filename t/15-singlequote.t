use lib qw(./lib ./blib/lib ./blib/arch);
use Test::More;
use strict;
BEGIN { plan tests => 7 };
use JSON::PC;

#########################
my ($js,$obj);
my $pc = new JSON::PC;

#local $JSON::SingleQuote = 1;
$pc->singlequote(1);

$obj = { foo => "bar" };
$js = $pc->convert($obj);

is($js, q|{'foo':'bar'}|);

#$JSON::SingleQuote = 0;
$pc->singlequote(0);

$js = $pc->convert($obj);
is($js, q|{"foo":"bar"}|);

$js = $pc->convert($obj, {singlequote => 1});
is($js, q|{'foo':'bar'}|);

$pc = new JSON::PC (singlequote => 1);

is($pc->to_json($obj), q|{'foo':'bar'}|);

$pc->singlequote(0);
is($pc->to_json($obj), q|{"foo":"bar"}|);

$obj = { foo => "b\"ar" };
is($pc->to_json($obj), q|{"foo":"b\\"ar"}|);

$obj = { foo => "b'ar" };
$pc->singlequote(1);
is($pc->to_json($obj), q|{'foo':'b\'ar'}|);
