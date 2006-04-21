use lib qw(./lib ./blib/lib ./blib/arch);
use Test::More;
use strict;
BEGIN { plan tests => 40 };
use JSON::PC;

use CGI;
use IO::File;

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

my ($obj, $obj2, $js);
my $pc = new JSON::PC;

$obj  = new MyTest;
$js = $pc->convert($obj);
ok(!defined $js);

{
#local $JSON::ConvBlessed = 1;
#local $JSON::AUTOCONVERT = 1;

$pc->convblessed(1);

my ($obj, $obj2, $js);

$obj  = new MyTest;
$obj2 = new MyTest2;

@{$obj2} = (1,2,3);

$obj->{a} = $obj2;
$obj->{b} = q|{'a' => bless( {}, 'MyTest' )}|;
$obj->{c} = new CGI;
$obj->{d} = JSON::Number(1.3);
$obj->{e} = 1.3;

$js = $pc->convert($obj);


like($js, qr/"a":\[1,2,3\]/);
like($js, qr/"b":"{'a' => bless\( {}, 'MyTest' \)}"/);
like($js, qr/"d":1.3/);
like($js, qr/"e":1.3/);

my $obj3 = $pc->parse($js);

is($obj3->{a}->[0], $obj->{a}->[0]);
is($obj3->{a}->[1], $obj->{a}->[1]);
is($obj3->{a}->[2], $obj->{a}->[2]);

is($obj3->{b}, $obj->{b});
is($obj3->{d}, "$obj->{d}");

$js = $pc->convert([$obj]);

like($js, qr/^\[{"[a-e]"/);
like($js, qr/"a":\[1,2,3\]/);
like($js, qr/"b":"{'a' => bless\( {}, 'MyTest' \)}"/);
like($js, qr/"d":1.3/);

$js = $pc->convert({hoge => $obj});

like($js, qr/^{"hoge":{"[a-e]"/);
like($js, qr/"a":\[1,2,3\]/);
like($js, qr/"b":"{'a' => bless\( {}, 'MyTest' \)}"/);
like($js, qr/"d":1.3/);

}



{
$pc->convblessed(1);
$pc->autoconv(1);


$obj  = new MyTest;
$obj2 = new MyTest2;

@{$obj2} = (1,2,3);

$obj->{a} = $obj2;
$obj->{b} = q|{'a' => bless( {}, 'MyTest' )}|;
$obj->{c} = new CGI;
$obj->{d} = JSON::Number(1.3);
$obj->{e} = 1.3;

$js = $pc->convert($obj);

#print $js,"\n";

like($js, qr/"a":\[1,2,3\]/);
like($js, qr/"b":"{'a' => bless\( {}, 'MyTest' \)}"/);
like($js, qr/"d":1.3/);
like($js, qr/"e":1.3/);

my $obj3 = $pc->parse($js);

is($obj3->{a}->[0], $obj->{a}->[0]);
is($obj3->{a}->[1], $obj->{a}->[1]);
is($obj3->{a}->[2], $obj->{a}->[2]);

is($obj3->{b}, $obj->{b});
is($obj3->{d}, "$obj->{d}");

}


{
$pc->convblessed(1);
$pc->autoconv(0);

$obj  = new MyTest;
$obj2 = new MyTest2;

@{$obj2} = (JSON::Number(1),JSON::Number(2),JSON::Number(3));

$obj->{a} = $obj2;
$obj->{b} = q|{'a' => bless( {}, 'MyTest' )}|;
$obj->{c} = new CGI;
$obj->{d} = JSON::Number(1.3);
$obj->{e} = 1.3;

$js = $pc->convert($obj);

#print $js,"\n";

like($js, qr/"a":\[1,2,3\]/);
like($js, qr/"b":"{'a' => bless\( {}, 'MyTest' \)}"/);
like($js, qr/"d":1.3/);
like($js, qr/"e":"1.3"/);

my $obj3 = $pc->parse($js);

is($obj3->{a}->[0], "$obj->{a}->[0]");
is($obj3->{a}->[1], "$obj->{a}->[1]");
is($obj3->{a}->[2], "$obj->{a}->[2]");

is($obj3->{b}, $obj->{b});
is($obj3->{d}, "$obj->{d}");

}
$pc->autoconv(1);

#my $json = new JSON;

$obj  = new MyTest;
$obj2 = new MyTest2;

@{$obj2} = (1,2,3);

$obj->{a} = $obj2;
$obj->{b} = q|{'a' => bless( {}, 'MyTest' )}|;
$obj->{c} = new CGI;
$obj->{d} = JSON::Number(1.3);
$obj->{e} = 1.3;

$pc->convblessed(1);
$js = $pc->convert($obj);
like($js, qr/"a":\[1,2,3\]/);

$pc->convblessed(0);
$js = $pc->convert($obj);
ok(!defined $js);

$pc = JSON::PC->new(convblessed => 0);
$js = $pc->convert($obj);
ok(!defined $js);

$pc = JSON::PC->new(convblessed => 1);
$js = $pc->convert($obj);
like($js, qr/"a":\[1,2,3\]/);

########################
package MyTest;

use overload (
	'""' => sub { 'test' },
);

sub new  { bless {}, shift; }


package MyTest2;

use overload (
	'""' => sub { 'test' },
);

sub new  { bless [], shift; }

__END__
