#!/usr/bin/perl -w
use lib qw(./lib ./blib/lib ./blib/arch);
use strict;
use Test::More;
BEGIN { plan tests => 17 };

use JSON::PC;

my ($js,$obj,$json);
my $pc = new JSON::PC;

$obj = {foo => "bar"};
$js = $pc->convert($obj);
is($js,q|{"foo":"bar"}|);

$obj = [10, "hoge", {foo => "bar"}];
$js = $pc->convert($obj, {pretty => 1});
is($js,q|[
  10,
  "hoge",
  {
    "foo" : "bar"
  }
]|);

$obj = [10, "hoge", {foo => "bar"}];
$js = $pc->convert($obj, {pretty => 1, indent => 1});
is($js,q|[
 10,
 "hoge",
 {
  "foo" : "bar"
 }
]|, "indent => 1");

$obj = { foo => [ {a=>"b"}, 0, 1, 2 ] };
$js = $pc->convert($obj);
is($js,q|{"foo":[{"a":"b"},0,1,2]}|);


$obj = { foo => [ {a=>"b"}, 0, 1, 2 ] };
$js = $pc->convert($obj, {pretty => 1});
is($js,q|{
  "foo" : [
    {
      "a" : "b"
    },
    0,
    1,
    2
  ]
}|);

$obj = { foo => [ {a=>"b"}, 0, 1, 2 ] };
$js = $pc->convert($obj);
is($js,q|{"foo":[{"a":"b"},0,1,2]}|);


$obj = {foo => "bar"};
$js = $pc->convert($obj);
is($js,q|{"foo":"bar"}|, "OOP");

$obj = [10, "hoge", {foo => "bar"}];
$js = $pc->convert($obj, {pretty => 1});
is($js,q|[
  10,
  "hoge",
  {
    "foo" : "bar"
  }
]|, "OOP");

$obj = { foo => [ {a=>"b"}, 0, 1, 2 ] };
$js = $pc->convert($obj);
is($js,q|{"foo":[{"a":"b"},0,1,2]}|, "OOP");


$pc = new JSON::PC(pretty => 1);

$obj = { foo => [ {a=>"b"}, 0, 1, 2 ] };
$js = $pc->convert($obj);
is($js,q|{
  "foo" : [
    {
      "a" : "b"
    },
    0,
    1,
    2
  ]
}|, "OOP new JSON (pretty => 1)");

$js = $pc->convert($obj);
is($js,q|{
  "foo" : [
    {
      "a" : "b"
    },
    0,
    1,
    2
  ]
}|, "OOP (pretty => 1)");

$js = $pc->convert($obj, {pretty => 0});
is($js,q|{"foo":[{"a":"b"},0,1,2]}|, "OOP (pretty => 0)");

$pc->pretty(1);
$js = $pc->convert($obj);
is($js,q|{
  "foo" : [
    {
      "a" : "b"
    },
    0,
    1,
    2
  ]
}|, "OOP (pretty => 1)");

$pc->pretty(0);
$js = $pc->convert($obj);
is($js,q|{"foo":[{"a":"b"},0,1,2]}|, "OOP (pretty => 0)");

$obj = {foo => "bar"};
$pc->pretty(1);
$pc->delimiter(0);
is($pc->convert($obj), qq|{\n  "foo":"bar"\n}|, "delimiter 0");
$pc->delimiter(1);
is($pc->convert($obj), qq|{\n  "foo": "bar"\n}|, "delimiter 1");
$pc->delimiter(2);
is($pc->convert($obj), qq|{\n  "foo" : "bar"\n}|, "delimiter 2");
