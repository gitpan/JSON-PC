use lib qw(./lib ./blib/lib ./blib/arch);
use Test::More;
use strict;
BEGIN { plan tests => 24 };
use JSON::PC;

#########################
my ($js,$obj);
my $pc = new JSON::PC;

$js  = '{"foo":0x00}';
$obj = $pc->parse($js);
is($obj->{foo}, 0, "hex 00");

$js  = '{"foo":0x01}';
$obj = $pc->parse($js);
is($obj->{foo}, 1, "hex 01");

$js  = '{"foo":0x0a}';
$obj = $pc->parse($js);
is($obj->{foo}, 10, "hex 0a");

$js  = '{"foo":0x10}';
$obj = $pc->parse($js);
is($obj->{foo}, 16, "hex 10");

$js  = '{"foo":0xff}';
$obj = $pc->parse($js);
is($obj->{foo}, 255, "hex ff");

$js  = '{"foo":000}';
$obj = $pc->parse($js);
is($obj->{foo}, 0, "oct 0");

$js  = '{"foo":001}';
$obj = $pc->parse($js);
is($obj->{foo}, 1, "oct 1");

$js  = '{"foo":010}';
$obj = $pc->parse($js);
is($obj->{foo}, 8, "oct 10");

$js  = '{"foo":0x0g}';
eval q{ $obj = $pc->parse($js) };
like($@, qr/Bad object/i, 'Bad object (hex)');

$js  = '{"foo":008}';
eval q{ $obj = $pc->parse($js) };
like($@, qr/Bad object/i, 'Bad object (oct)');


$js  = '{"foo":0}';
$obj = $pc->parse($js);
is($obj->{foo}, 0, "normal 0");

$js  = '{"foo":0.1}';
$obj = $pc->parse($js);
is($obj->{foo}, 0.1, "normal 0.1");


$js  = '{"foo":10}';
$obj = $pc->parse($js);
is($obj->{foo}, 10, "normal 10");

$js  = '{"foo":-10}';
$obj = $pc->parse($js);
is($obj->{foo}, -10, "normal -10");


$js  = '{"foo":0, "bar":0.1}';
$obj = $pc->parse($js);
is($obj->{foo},0,  "normal 0");
is($obj->{bar},0.1,"normal 0.1");

$js  = '{"foo":[0, 012, 0xFA, 0.123, -0.123, true], "bar":0.1, "hoge":0xfa}';
$obj = $pc->parse($js);
is($obj->{foo}->[0], 0,      "complex structure");
is($obj->{foo}->[1], 10,     "complex structure");
is($obj->{foo}->[2], 250,    "complex structure");
is($obj->{foo}->[3], 0.123,  "complex structure");
is($obj->{foo}->[4], -0.123, "complex structure");
is(qq|$obj->{foo}->[5]| , 'true', "complex structure");
is($obj->{bar},  0.1,      "complex structure");
is($obj->{hoge}, 250,      "complex structure");

