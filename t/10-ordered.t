use lib qw(./lib ./blib/lib ./blib/arch);
use Test::More;
use strict;
BEGIN { plan tests => 8 };
use JSON::PC;
#########################

my ($js,$obj);
my $pc = new JSON::PC;

{
local $JSON::KeySort = 'My::Package::sort_test';

$obj = {a=>1, b=>2, c=>3, d=>4, e=>5, f=>6, g=>7, h=>8, i=>9};
$js = $pc->convert($obj);
is($js, q|{"a":1,"b":2,"c":3,"d":4,"e":5,"f":6,"g":7,"h":8,"i":9}|);

$JSON::KeySort = 'My::Package::sort_test2';
$js = $pc->convert($obj);
is($js, q|{"i":9,"h":8,"g":7,"f":6,"e":5,"d":4,"c":3,"b":2,"a":1}|);

}

$pc->keysort(\&My::Package::sort_test);
$js = $pc->convert($obj);
is($js, q|{"a":1,"b":2,"c":3,"d":4,"e":5,"f":6,"g":7,"h":8,"i":9}|);

$pc->keysort(\&My::Package::sort_test2);
$js = $pc->convert($obj);
is($js, q|{"i":9,"h":8,"g":7,"f":6,"e":5,"d":4,"c":3,"b":2,"a":1}|);

$pc = new JSON::PC(keysort => \&My::Package::sort_test);
$pc->pretty(1);
$js = $pc->convert($obj);

is($js, q|{
  "a" : 1,
  "b" : 2,
  "c" : 3,
  "d" : 4,
  "e" : 5,
  "f" : 6,
  "g" : 7,
  "h" : 8,
  "i" : 9
}|);

$js = $pc->convert($obj, {keysort => \&My::Package::sort_test2});
is($js, q|{
  "i" : 9,
  "h" : 8,
  "g" : 7,
  "f" : 6,
  "e" : 5,
  "d" : 4,
  "c" : 3,
  "b" : 2,
  "a" : 1
}|);


$pc->pretty(0);
$pc->keysort(1);

$js = $pc->convert($obj);
is($js, q|{"a":1,"b":2,"c":3,"d":4,"e":5,"f":6,"g":7,"h":8,"i":9}|);


$js = $pc->convert($obj, {keysort => 1});
is($js, q|{"a":1,"b":2,"c":3,"d":4,"e":5,"f":6,"g":7,"h":8,"i":9}|);


package My::Package;

sub sort_test {
    $JSON::Converter::a cmp $JSON::Converter::b;
}

sub sort_test2 {
    $JSON::Converter::b cmp $JSON::Converter::a;
}
