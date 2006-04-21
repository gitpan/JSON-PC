use lib qw(./lib ./blib/lib ./blib/arch);
use Test::More;
use strict;
BEGIN { plan tests => 21 };
use JSON::PC;
#
# このファイルのエンコーディングはUTF-8
#
#########################
my ($js,$obj);
my $pc = new JSON::PC;

SKIP: {
#  skip "can't use utf8.", 21, unless( JSON->USE_UTF8 );

  if($] == 5.008){
     require Encode;
     *utf8::is_utf8 = sub { Encode::is_utf8($_[0]); }
  }


$js  = q|{"foo":"ばぁ"}|;

$pc->utf8(0);

$obj = $pc->parse($js);
ok(!utf8::is_utf8($obj->{foo}), 'no UTF8 option');

$obj = $pc->parse($js, {utf8 => 1});
ok(utf8::is_utf8($obj->{foo}), 'UTF8 option');

$js = $pc->convert($obj);
ok(utf8::is_utf8($js), 'with UTF8');

$js  = q|{"foo":"ばぁ"}|;
$obj = $pc->parse($js);
ok(!utf8::is_utf8($js), 'without UTF8');

{
 use utf8;
 $js  = q|{"foo":"ばぁ"}|;
 $obj = $pc->parse($js);
 ok(utf8::is_utf8($obj->{foo}), 'with UTF8');
}

$js  = q|{"foo":"ばぁ"}|;

#my $json = new JSON;

$obj = $pc->parse($js,);
ok(!utf8::is_utf8($obj->{foo}), 'no utf8 option');

$obj = $pc->parse($js, {utf8 => 1});
ok(utf8::is_utf8($obj->{foo}), 'with utf8 option');

$js = $pc->convert($obj);
ok(utf8::is_utf8($js), 'utf8 option');

$js = $pc->convert($obj);
ok(utf8::is_utf8($js), 'with UTF8 flag');





$js  = q|{"foo":"ばぁ"}|; # no UTF8


{
$pc->utf8(1);

$obj = $pc->parse($js);
ok(utf8::is_utf8($obj->{foo}), 'utf8 => 1');

$js = $pc->convert($obj);
ok(utf8::is_utf8($js));

$js  = q|{"foo":"ばぁ"}|; # no UTF8

$obj = $pc->parse($js, {utf8 => 0});
ok(!utf8::is_utf8($obj->{foo}), '$JSON::UTF8 = 1 but option is 0');

$obj = $pc->parse($js);
ok(utf8::is_utf8($obj->{foo}));

$pc->utf8(0);

$js  = q|{"foo":"ばぁ"}|; # no UTF8

$obj = $pc->parse($js);
$js = $pc->convert($obj);
ok(!utf8::is_utf8($js), 'no UTF8');

}

#$pc->utf8(0);


{

    $js = q|["\u3042\u3044"]|;
    $obj = $pc->parse($js);

    ok( $obj->[0], q|["\u3042\u3044"]| );
    ok( !utf8::is_utf8($obj->[0]) );

    $obj = $pc->parse($js, {utf8 => 1});
    ok( utf8::is_utf8($obj->[0]) );


    $js = q|{"\u3042\u3044" : "\u3042\u3044"}|;
    $obj = $pc->parse($js);
    ok( $obj->{"あい"}, '\u3042\u3044' );

    ok(! utf8::is_utf8($obj->{"あい"}) );

    $obj = $pc->parse($js, {utf8 => 1});

  { use utf8;
    ok( utf8::is_utf8($obj->{"あい"}) );
    is($obj->{"あい"}, "あい");
  }
}

} # END





__END__

