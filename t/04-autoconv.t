use Test::More;
use strict;
use lib qw(./lib ./blib/lib ./blib/arch);

BEGIN { plan tests => 12 };
use JSON::PC;

# See JSON::Parser for JSON::NotString.

sub JSON::Number {
    my $num = shift;

    return undef if(!defined $num);

    if(    $num =~ /^-?(?:\d+)(?:\.\d*)?(?:[eE][-+]?\d+)?$/
        or $num =~ /^0[xX](?:[0-9a-zA-Z])+$/                 )
    {
        return bless {value => $num}, 'JSON::NotString';
    }
    else{
        return undef;
    }
}


my $pc = JSON::PC->new;
my ($js,$obj);

$obj = {"id" => JSON::Number("1.02")};

$js = $pc->convert($obj);
is($js,'{"id":1.02}', "json::number");


$obj = {"id" => "1.02"};

$js = $pc->convert($obj);
is($js,'{"id":1.02}', 'normal default');

$pc->autoconv(0);
$js = $pc->convert($obj);
is($js,'{"id":"1.02"}', "no autoconv");

$pc->autoconv(1);
$js = $pc->convert($obj);
is($js,'{"id":1.02}', "autoconv");

$js = $pc->convert($obj, {autoconv => 0});
is($js,'{"id":"1.02"}', "option");

$pc->autoconv(1);

$js = $pc->convert($obj);
is($js,'{"id":1.02}');

$js = $pc->convert($obj, {autoconv => 0});
is($js,'{"id":"1.02"}');

$js = $pc->convert($obj, {autoconv => 1});
is($js,'{"id":1.02}');


$obj = {"id" => 1.02};

$pc->autoconv(0);

$js = $pc->convert($obj);
is($js,'{"id":"1.02"}');

$pc->autoconv(1);

$js = $pc->convert($obj);
is($js,'{"id":1.02}');

$js = JSON::PC::convert($obj);
is($js,'{"id":1.02}');

$js = JSON::PC::convert($obj, {autoconv => 0});
is($js,'{"id":"1.02"}');

