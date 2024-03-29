use lib qw(./lib ./blib/lib ./blib/arch);
use Test::More;
use strict;
BEGIN { plan tests => 4 };
use JSON::PC;

my $pc = new JSON::PC;

my $obj = {a => 123};
my $obj1 = {};
my $obj2 = {};
my $obj3 = {};

$obj1->{a} = $obj1;

eval q{ $pc->convert($obj1) };
like($@, qr/circle ref/);

$obj1->{a} = $obj2;
$obj2->{b} = $obj3;
$obj3->{c} = $obj;

eval q{ $pc->convert($obj1) };
unlike($@, qr/circle ref/);
#is(objToJson($obj1), q|{"a":{"b":{"c":{"a":123}}}}|);

$obj1->{a} = $obj2;
$obj2->{b} = $obj3;
$obj3->{c} = $obj1;

eval q{ $pc->convert($obj1) };
like($@, qr/circle ref/);

$obj1->{a} = [];
$obj2->{b} = {};

$obj1->{a}->[0] = $obj2;
$obj2->{b}->{c} = $obj1;

eval q{ $pc->convert($obj1) };
like($@, qr/circle ref/);

