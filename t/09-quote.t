use lib qw(./lib ./blib/lib ./blib/arch);
use Test::More;
use strict;
BEGIN { plan tests => 47 };
use JSON::PC;
#
# このファイルのエンコーディングはUTF-8
#
#########################
my ($js,$obj);
my $pc = new JSON::PC (utf8 => 0);

{
  $pc->barekey(1);
  $pc->quotapos(1);

$js  = q|{}|;
$obj = $pc->parse($js);
$js  = $pc->convert($obj);
is($js,'{}');

$js  = q|[]|;
$obj = $pc->parse($js);
$js  = $pc->convert($obj);
is($js,'[]');

$js  = q|{"foo":"bar"}|;
$obj = $pc->parse($js);
is($obj->{foo},'bar');
$js = $pc->convert($obj);
is($js,'{"foo":"bar"}');

$js  = q|{foo:"bar"}|;
$obj = $pc->parse($js);
is($obj->{foo},'bar');
$js = $pc->convert($obj);
is($js,'{"foo":"bar"}');

$js  = q|{ふぅ:"ばぁ"}|;
$obj = $pc->parse($js);
is($obj->{"ふぅ"},'ばぁ', 'utf8');

$js  = q|{漢字！:"ばぁ"}|;
$obj = $pc->parse($js);
is($obj->{"漢字！"},'ばぁ', 'utf8');


$js  = q|{foo:'bar'}|;
$obj = $pc->parse($js);
is($obj->{foo},'bar');
$js = $pc->convert($obj);
is($js,'{"foo":"bar"}');

$js  = q|{"foo":'bar'}|;
$obj = $pc->parse($js);
is($obj->{foo},'bar');
$js = $pc->convert($obj);
is($js,'{"foo":"bar"}');

$js  = q|{"foo":'b\'ar'}|;
$obj = $pc->parse($js);
is($obj->{foo},'b\'ar');
$js = $pc->convert($obj);
is($js,q|{"foo":"b'ar"}|);

$js  = q|{f'oo:"bar"}|;
$obj = eval q| $pc->parse($js) |;
like($@, qr/Bad object/i);

$js  = q|{'foo':'bar'}|;
$obj = $pc->parse($js);
is($obj->{foo},'bar');
$js = $pc->convert($obj);
is($js,'{"foo":"bar"}');

$js  = q|{"foo":""}|;
$obj = $pc->parse($js);
$js = $pc->convert($obj);
is($js,'{"foo":""}');

$js  = q|{foo:""}|;
$obj = $pc->parse($js);
$js = $pc->convert($obj);
is($js,'{"foo":""}');

$js  = q|{"foo":''}|;
$obj = $pc->parse($js);
$js = $pc->convert($obj);
is($js,'{"foo":""}');

$js  = q|{foo:''}|;
$obj = $pc->parse($js);
$js = $pc->convert($obj);
is($js,'{"foo":""}');

$js = q|[{foo:[1,2,3]},-0.12,{a:"b"}]|;
$obj = $pc->parse($js);
is(join(',',@{$obj->[0]->{foo}}),'1,2,3');
is(join(',',$obj->[1]),'-0.12');
is(join(',',$obj->[2]->{a}),'b');
$js = $pc->convert($obj);
is($js,q|[{"foo":[1,2,3]},-0.12,{"a":"b"}]|);

$js = q|[{'foo':[1,2,3]},-0.12,{a:'b'}]|;
$obj = $pc->parse($js);
is(join(',',@{$obj->[0]->{foo}}),'1,2,3');
is(join(',',$obj->[1]),'-0.12');
is(join(',',$obj->[2]->{a}),'b');
$js = $pc->convert($obj);
is($js,q|[{"foo":[1,2,3]},-0.12,{"a":"b"}]|);

}


{
  $pc->barekey(1);
  $pc->quotapos(0);


$js  = q|{}|;
$obj = $pc->parse($js);
$js  = $pc->convert($obj);
is($js,'{}');

$js  = q|[]|;
$obj = $pc->parse($js);
$js  = $pc->convert($obj);
is($js,'[]');

$js  = q|{"foo":"bar"}|;
$obj = $pc->parse($js);
is($obj->{foo},'bar');
$js = $pc->convert($obj);
is($js,'{"foo":"bar"}');

$js  = q|{foo:"bar"}|;
$obj = $pc->parse($js);
is($obj->{foo},'bar');
$js = $pc->convert($obj);
is($js,'{"foo":"bar"}');

$js  = q|{foo:'bar'}|;
$obj = eval q| $pc->parse($js) |;
like($@, qr/Syntax error/i);

$js  = q|{"foo":'bar'}|;
$obj = eval q| $pc->parse($js) |;
like($@, qr/Syntax error/i);

$js  = q|{'foo':'bar'}|;
$obj = eval q| $pc->parse($js) |;
like($@, qr/Bad String/i);

$js  = q|{"foo":""}|;
$obj = $pc->parse($js);
$js = $pc->convert($obj);
is($js,'{"foo":""}');

$js  = q|{foo:""}|;
$obj = $pc->parse($js);
$js = $pc->convert($obj);
is($js,'{"foo":""}');

$js  = q|{"foo":''}|;
$obj = eval q| $pc->parse($js) |;
like($@, qr/Syntax error/i);

$js  = q|{foo:''}|;
$obj = eval q| $pc->parse($js) |;
like($@, qr/Syntax error/i);

$js = q|[{foo:[1,2,3]},-0.12,{a:"b"}]|;
$obj = $pc->parse($js);
is(join(',',@{$obj->[0]->{foo}}),'1,2,3');
is(join(',',$obj->[1]),'-0.12');
is(join(',',$obj->[2]->{a}),'b');
$js = $pc->convert($obj);
is($js,q|[{"foo":[1,2,3]},-0.12,{"a":"b"}]|);

$js = q|[{foo:[1,2,3]},-0.12,{a:'b'}]|;
$obj = eval q| $pc->parse($js) |;
like($@, qr/Syntax error/i);

}

__END__

