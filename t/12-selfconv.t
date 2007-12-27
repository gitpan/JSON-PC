#+++ JSON-1.01.modified/t/12-selfconvert.t	2005-12-19 11:42:36.000000000 +0100
#@@ -0,0 +1,109 @@

use lib qw(./lib ./blib/lib ./blib/arch);
use Test::More;
use strict;
BEGIN { plan tests => 15 };
use JSON::PC;

my ($obj, $obj2, $js);

my $pc = new JSON::PC;

## If selfconvert isn't enabled, it gets converted as usual 
$obj  = new MyTest;
$js = $pc->convert($obj);
ok(!defined $js, "Everything works as usual if not enabled");

eval { $pc->convert({a => $obj}) };
like $@, qr/Invalid value/, "skip invalid if you want smth...";

{
  #local $JSON::SkipInvalid = 1;
  $pc->skipinvalid(1);
  $js = $pc->convert({a => $obj});
  cmp_ok($js, 'eq', '{"a":null}', "Everything works as usual if not enabled");
}

$pc->skipinvalid(0);

## Now let's try with the SelfConvert option
{
    #local $JSON::SelfConvert = 1;
    $pc->selfconvert(1);

    # the default 
    $obj  = new MyTest;
#    $obj  = new MyTestSub;

    $js = $pc->convert($obj);
    cmp_ok $js, 'eq', 'default', "self converted !";

    my $hash = {b => "c", d => ["e", 1], f => { g => 'h' } };
    my $array = [ 'a', -0.12, {c => 'd'}, 0x0E, 100_000_000, 10E3];
    my $value = "value{},[]:";

    my @tests = ( 
        {
            mesg     => "_toJson call", 
            expected => '{"a":"b"}',
            meth     => sub { $_[1]->_toJson({ a => 'b'}) },
        },
        {
            mesg     => "call to hashToJson", 
            expected => '{"a":'.$pc->convert($hash).'}', 
            meth     => sub { '{"a":'. $_[1]->hashToJson($hash). '}' },
        },
        {
            mesg     => "call to arrayToJson", 
            expected => $pc->convert($array), 
            meth     => sub { $_[1]->arrayToJson($array) },
        },
        {
            mesg     => "call to valueToJson", 
            expected => $pc->convert({a => $value }), 
            meth     => sub { '{"a":'. $_[1]->valueToJson($value).'}' },
        },
    );

    for (@tests) {
        $obj->{json} = $_->{meth};
        cmp_ok $pc->convert($obj), 'eq', $_->{expected}, $_->{mesg};
    }

    # as a Hash value (no conflict with skipinvalid)
    $obj->{json} = sub { '"youhou"' };
    cmp_ok $pc->convert({a => $obj}), 'eq', '{"a":"youhou"}', "hash - skipinvalid not necessary"; 

    # as an Array member (no conflict with skipinvalid) 
    $obj->{json} = sub { '"youhou"' };
    cmp_ok $pc->convert(['a', $obj]), 'eq', '["a","youhou"]', "array - skipinvalid not necessary"; 
    # null / false / true 
    for (qw(null false true)) {
        $obj->{json} = sub { $_ };
        cmp_ok $pc->convert({a => $obj}), 'eq', "{\"a\":$_}", "obj to $_ value"; 
    }

    # circle ref 1
    $obj->{json} = sub { 
        my $self = shift; # $obj
        my $json = shift;
        $json->_hashToJson({ a => $self });
    };

    eval { $js = $pc->convert($obj); };
    like($@, qr/circle ref/, "don't ask an object to recursively jsonize itself");

    # circle ref 2
    $obj->{json} = sub { 
        my $self = shift; # $obj
        my $json = shift;
        my $struct1 = { b => 'c' };
        my $struct2 = { d => $struct1 };
        $struct1->{b} = $struct2;
        $json->_hashToJson({ a => $struct1 });
    };
    eval { $js = $pc->convert($obj); };
    like($@, qr/circle ref/, "usual circle ref is detected");
}

########################
package MyTest;

sub new { return bless { json => sub { 'default' } }, 'MyTest'; }

sub toJson {
    my $self = shift;
    return $self->{json}->($self, @_);
}

package MyTestSub;

use base qw(MyTest);
sub new { return bless { json => sub { 'default' } }, 'MyTestSub'; }

__END__
