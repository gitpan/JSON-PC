#
# このファイルのエンコーディングはUTF-8
#
use lib qw(./lib ./blib/lib ./blib/arch);

use Test::More;
use strict;
BEGIN { plan tests => 17 };
use JSON::PC;

#########################
my ($js,$obj,$str);

my $pc = new JSON::PC (utf8 => 0);

$obj = {test => qq|abc"def|};
$str = $pc->convert($obj);
is($str,q|{"test":"abc\"def"}|);

$obj = {qq|te"st| => qq|abc"def|};
$str = $pc->convert($obj);
is($str,q|{"te\"st":"abc\"def"}|);

$obj = {test => qq|abc/def|};   # / => \/
$str = $pc->convert($obj);         # but since version 0.99
is($str,q|{"test":"abc/def"}|); # this handling is deleted.
$obj = $pc->parse($str);
is($obj->{test},q|abc/def|);

$obj = {test => q|abc\def|};
$str = $pc->convert($obj);
is($str,q|{"test":"abc\\\\def"}|);

$obj = {test => "abc\bdef"};
$str = $pc->convert($obj);
is($str,q|{"test":"abc\bdef"}|);

$obj = {test => "abc\fdef"};
$str = $pc->convert($obj);
is($str,q|{"test":"abc\fdef"}|);

$obj = {test => "abc\ndef"};
$str = $pc->convert($obj);
is($str,q|{"test":"abc\ndef"}|);

$obj = {test => "abc\rdef"};
$str = $pc->convert($obj);
is($str,q|{"test":"abc\rdef"}|);

$obj = {test => "abc-def"};
$str = $pc->convert($obj);
is($str,q|{"test":"abc-def"}|);

$obj = {test => "abc(def"};
$str = $pc->convert($obj);
is($str,q|{"test":"abc(def"}|);

$obj = {test => "abc\\def"};
$str = $pc->convert($obj);
is($str,q|{"test":"abc\\\\def"}|);

$obj = {test => "あいうえお"};
$str = $pc->convert($obj);
is($str,q|{"test":"あいうえお"}|);

$obj = {"あいうえお" => "かきくけこ"};
$str = $pc->convert($obj);
is($str,q|{"あいうえお":"かきくけこ"}|);

$obj = $pc->parse(q|{"id":"abc\ndef"}|);
is($obj->{id},"abc\ndef",q|{"id":"abc\ndef"}|);

$obj = $pc->parse(q|{"id":"abc\\\ndef"}|);
is($obj->{id},"abc\\ndef",q|{"id":"abc\\\ndef"}|);

$obj = $pc->parse(q|{"id":"abc\\\\\ndef"}|);
is($obj->{id},"abc\\\ndef",q|{"id":"abc\\\\\ndef"}|);
