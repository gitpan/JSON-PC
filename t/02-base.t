use Test::More;
use lib qw(./lib ./blib/lib ./blib/arch);

# check autoconv, unmapping, execcoderef, skipinvalid

use strict;
BEGIN { plan tests => 46 };
use JSON::PC;

sub JSON::True {
    bless {value => 'true'}, 'JSON::NotString';
}

sub JSON::False {
    bless {value => 'false'}, 'JSON::NotString';
}

sub JSON::Null {
    bless {value => undef}, 'JSON::NotString';
}


#########################
my ($js,$obj);

my $pc = new JSON::PC;

$js  = q|{}|;

$obj = $pc->parse($js);
$js  = $pc->convert($obj);
is($js,'{}', '{}');

$js  = q|[]|;
$obj = $pc->parse($js);
$js  = $pc->convert($obj);
is($js,'[]', '[]');


$js  = q|{"foo":"bar"}|;
$obj = $pc->parse($js);
is($obj->{foo},'bar');
$js  = $pc->convert($obj);
is($js,'{"foo":"bar"}', '{"foo":"bar"}');

$js  = q|{"foo":""}|;
$obj = $pc->parse($js);
$js  = $pc->convert($obj);
is($js,'{"foo":""}', '{"foo":""}');

$js  = q|{"foo":" "}|;
$obj = $pc->parse($js);
$js  = $pc->convert($obj);
is($js,'{"foo":" "}' ,'{"foo":" "}');

$js  = q|{"foo":"0"}|;
$obj = $pc->parse($js);
$js  = $pc->convert($obj);
is($js,'{"foo":0}',q|{"foo":0} - autoconvert (default)|);


$js  = q|{"foo":"0"}|;
$obj = $pc->parse($js);
$js  = $pc->convert($obj, {autoconv => 0});
is($js,'{"foo":"0"}',q|{"foo":"0"} - no autoconv|);

$pc->autoconv(1);

$js  = q|{"foo":"0 0"}|;
$obj = $pc->parse($js);
$js  = $pc->convert($obj);
is($js,'{"foo":"0 0"}','{"foo":"0 0"}');

$js  = q|[1,2,3]|;
$obj = $pc->parse($js);
is(join(',',@$obj),'1,2,3');
$js  = $pc->convert($obj);
is($js,'[1,2,3]');

$js = q|{"foo":[1,2,3]}|;
$obj = $pc->parse($js);
is(join(',',@{$obj->{foo}}),'1,2,3');
$js  = $pc->convert($obj);
is($js,'{"foo":[1,2,3]}');

$js = q|{"foo":{"bar":"hoge"}}|;
$obj = $pc->parse($js);
is($obj->{foo}->{bar},'hoge');
$js  = $pc->convert($obj);
is($js,q|{"foo":{"bar":"hoge"}}|);

$js = q|[{"foo":[1,2,3]},-0.12,{"a":"b"}]|;
$obj = $pc->parse($js);
is(join(',',@{$obj->[0]->{foo}}),'1,2,3');
is(join(',',$obj->[1]),'-0.12');
is(join(',',$obj->[2]->{a}),'b');
$js  = $pc->convert($obj);
is($js,q|[{"foo":[1,2,3]},-0.12,{"a":"b"}]|);


$js  = q|[true,false,null]|;
$obj = $pc->parse($js);
isa_ok($obj->[0],'JSON::NotString');
isa_ok($obj->[1],'JSON::NotString');
isa_ok($obj->[2],'JSON::NotString');
ok($obj->[0],'true');
ok(!$obj->[1],'false');
ok(!$obj->[2],'null');
$js  = $pc->convert($obj);
is($js,'[true,false,null]');


$js  = q|[true,false,null]|;
$obj = $pc->parse($js, {unmapping => 1});
is($obj->[0],1,'unmapping option true');
is($obj->[1],0,'unmapping option false');
ok(!defined $obj->[2],'unmapping option null');

#$obj = $pc->parse($js);
#is("$obj->[0]",'true','not unmapping true');
#is("$obj->[1]",'false','not unmapping false');

$pc->unmapping(1);
$obj = $pc->parse($js);
is($obj->[0],1,'unmapping true (atr)');
is($obj->[1],0,'unmapping false(atr)');


$js  = $pc->convert([JSON::True, JSON::False, JSON::Null]);
is($js,'[true,false,null]', 'JSON::NotString [true,false,null]');



$obj = ["\x01"];
is($js = $pc->convert($obj),'["\\u0001"]');
$obj = $pc->parse($js);
is($obj->[0],"\x01");

$obj = ["\e"];
is($js = $pc->convert($obj),'["\\u001b"]');
$obj = $pc->parse($js);
is($obj->[0],"\e");

$js = '{"id":"}';
eval q{ $pc->parse($js) };
#jsonToObj($js);
like($@, qr/Bad string/i, 'Bad string');


$pc->execcoderef(1);

$obj = { foo => sub { "bar"; } };
$js = $pc->convert($obj);
is($js, '{"foo":"bar"}', "coderef bar");

$obj = { foo => sub { return } };
$js = $pc->convert($obj);
is($js, '{"foo":null}', "coderef undef");

$obj = { foo => sub { [1, 2, {foo => "bar"}]; } };
$js = $pc->convert($obj);
is($js, '{"foo":[1,2,{"foo":"bar"}]}', "coderef complex");

$pc->execcoderef(0);
$pc->skipinvalid(1);

$obj = { foo => sub { "bar"; } };
$js = $pc->convert($obj);
is($js, '{"foo":null}', "skipinvalid && coderef bar");

$pc->skipinvalid(0);

$obj = { foo => sub { "bar"; } };
eval q{ $js = $pc->convert($obj) };
like($@, qr/Invalid value/i, 'invalid value (coderef)');


$obj = { foo => *STDERR };
$js = $pc->convert($obj);
is($js, '{"foo":"*main::STDERR"}', "type blog");

$obj = { foo => \*STDERR };
eval q{ $js = $pc->convert($obj) };
like($@, qr/Invalid value/i, 'invalid value (ref of type blog)');

$obj = { foo => bless {}, "Hoge" };
eval q{ $js = $pc->convert($obj) };
like($@, qr/Invalid value/i, 'invalid value (blessd object)');

$obj = { foo => \$js };
eval q{ $js = $pc->convert($obj) };
like($@, qr/Invalid value/i, 'invalid value (ref)');

