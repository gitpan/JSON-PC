package JSON::PC;

# JSON Parser and Converter

use 5.008;
use strict;
use vars qw($VERSION);


BEGIN {
    $VERSION = '0.02';
    require XSLoader;
    XSLoader::load('JSON::PC', $VERSION);
}

############
# METHODS
############
sub new {
    my $class = shift;
    bless {
        autoconv  => 1,
        delimiter => 2,
        indent    => 2,
        utf8      => 1,
        @_,
    }, $class;
}

sub parse {
    my $self = ($_[0] && ref $_[0]) ? shift : __PACKAGE__->new;
    $self->_parse(@_);
};


sub convert { # I want to use UNIVERSAL::isa but don't use.
    my $self = ($_[0] && UNIVERSAL::isa($_[0], __PACKAGE__))
                                    ? shift : __PACKAGE__->new;
    $self->_convert(@_);
};


# for JSON compatibility

*jsonToObj = *parse;
*objToJson = *convert;
*to_json   = *convert;
*to_obj    = *parse;

*hashToJson   = *convert;
*arrayToJson  = *convert;

*_hashToJson  = *convert;
*_arrayToJson = *convert;

##############
# ACCESSORS
##############
BEGIN{
    for my $name (qw/ autoconv pretty indent delimiter utf8
                      execcoderef skipinvalid quotapos barekey
                      unmapping keysort convblessed selfconvert singlequote
                    /)
    {
        eval qq{
            sub $name { \$_[0]->{$name} = \$_[1] if(defined \$_[1]); \$_[0]->{$name} }
        };
    }
}

##########################
# backward compatiblility
##########################
package JSON::Converter;

sub JSON::Converter::_sort_key {
    my ($sort, $array_ref) = @_;
    sort $sort (@$array_ref);
}


# I will move this subroutine to XS code....
package JSON::PC::Parser;

sub _chr { chr(shift); }

#########################
# for JSON compatibility
#########################
unless ($JSON::NotString::Defined) {
    eval q|
        package JSON::NotString;
        use overload (
            '""'   => sub { $_[0]->{value} },
            'bool' => sub {
                  ! defined $_[0]->{value}  ? undef
                : $_[0]->{value} eq 'false' ? 0 : 1;
            },
        );
        $JSON::NotString::Defined = 1;
    |;
}

####################################################
1;
__END__

=head1 NAME

JSON::PC -  fast JSON Parser and Converter

=head1 DEPRECATED

This module is too buggy and is not maintained.
Please try to use L<JSON::XS> which is faster than L<JSON::Syck> and
properly works.

Additionally, L<JSON> module now use L<JSON::XS> as the backend module
and if not available, it uses the pure Perl module L<JSON::PP>.
Theire interfaces are incompatible to old JSON module (version 1.xx).

See to L<JSON>.


=head1 SYNOPSIS

 use JSON::PC;
 
 my $json = new JSON::PC;
 
 my $obj  = $json->parse(q/{foo => [1,2,3], bar => "perl"}/);
 
 print $json->convert($obj);

 # or

 $obj = JSON::PC::parse(q/{foo => [1,2,3], bar => "perl"}/);
 print  JSON::PC::convert($obj);


=head1 DESCRIPTION

JSON::PC is a XS version of L<JSON::Parser> and L<JSON::Converter>.
This module supports all L<JSON> module options.


=head1 DIFFERENCE WITH JSON::Syck

You might want to know the difference between L<JSON::Syck> and JSON::PC.

Since JSON::Syck is based on libsyck, JSON::Syck is supposed to be very fast
and memory efficient. (from L<JSON::Syck> doc)

JSON::PC is (in many case) faster than JSON::Syck and
supports all JSON.pm options.
After verion 1.90, L<JSON> will calls JSON::PC by default.

Oh, and JSON::PC can use camelCase method names still :-(


=head1 METHODS

Except C<new> method, all methods are object method.

=over 4

=item new()

=item new(%option)

This is a class method and returns new JSON::PC object.

=item parse($str)

=item parse($str, $options_ref)

takes JSON foramt string and returns perl data structure.
C<jsonToObj> is an alias.

=item convert($obj)

=item convert($obj, $options_ref)

takes perl data structure and returns JSON foramt string.
C<objToJson> is an alias.


=item autoconv($int)

This is an accessor to C<autoconv>.
See L</AUTOCONVERT> for more info.

=item skipinvalid($int)

C<convert()> does C<die()> when it encounters any invalid data
(for instance, coderefs). If C<skipinvalid> is set with true(integer),
the function convets these invalid data into JSON format's C<null>.

=item execcoderef($int)

C<convert()> does C<die()> when it encounters any code reference.
However, if C<execcoderef> is set with true(integer),
executes the coderef and uses returned value.

=item pretty($int)

This is an accessor to C<pretty>.
When prrety is true(integer), C<objToJson()> returns
prrety-printed string. See L</PRETTY PRINTING> for more info.

=item indent($int)

This is an accessor to C<indent>.
See L</PRETTY PRINTING> for more info.

=item delimiter($int)

This is an accessor to C<delimiter>.
See L</PRETTY PRINTING> for more info.

=item unmapping($int)

This is an accessor to C<unmapping>.
See L</UNMAPPING OPTION> for more info.

=item keysort($int)

=item keysort($code_ref)

This is an accessor to C<keysort>.
See L</HASH KEY SORT ORDER> for more info.

=item convblessed($int)

This is an accessor to C<convblessed>.
See L</BLESSED OBJECT> for more info.

=item selfconvert($int)

This is an accessor to C<selfconvert>.
See L</BLESSED OBJECT> for more info.

=item singlequote($int)

This is an accessor to C<singlequote>.
See L</CONVERT WITH SINGLE QUOTES> for more info.

=item barekey($int)

You can set a true(integer) to parse bare keys of objects.

=item quotapos($int)

You can set a true(integer) to parse
any keys and values quoted by single quotations.

=item utf8($int)

This is an accessor to C<utf8>.
You can set a true(integer) to set UTF8 flag into strings contain utf8.

=back

=head1 OPTIONS


=head2 AUTOCONVERT

By default, C<autoconv> is true.

 (Perl) {num => 10.02}
 ( => JSON) {"num" : 10.02}

it is not C<{"num" : "10.02"}>.

But set 0:

 (Perl) {num => 10.02}
 ( => JSON) {"num" : "10.02"}

it is not C<{"num" : 10.02}>.

If you use JSON.pm, you can explicitly sepcify:

 $obj = {
    id     => JSON::Number(10.02),
    bool1  => JSON::True,
    bool2  => JSON::False,
    noval  => JSON::Null,
 };

 $json->convert($obj);
 # {"noval" : null, "bool2" : false, "bool1" : true, "id" : 10.02}

See L<JSON>.

=head2 UNMAPPING OPTION

By default, C<unMapping> is false and JSON::PC converts
C<null>, C<true>, C<false> into C<JSON::NotString> objects.
You can set true(integer) to stop the mapping function.
In that case, JSON::PC will convert C<null>, C<true>, C<false>
into C<undef>, 1, 0.

=head2 BARE KEY OPTION

You can set a true(integer) into C<barekey> for JSON::PC to parse
bare keys of objects.

 $json->barekey(1);
 $obj = $json->parse('{foo:"bar"}');

=head2 SINGLE QUOTATION OPTION

You can set a true(integer) for JSON::PC to parse
any keys and values quoted by single quotations.

 $json->quotapos(1);

 $obj = $json->parse(q|{"foo":'bar'}|);
 $obj = $json->parse(q|{'foo':'bar'}|);


=head2 HASH KEY SORT ORDER

By default C<convert> will serialize hashes with their keys in random
order.  To control the ordering of hash keys, you can provide a standard
'sort' function that will be used to control how hashes are converted.

You can provide either a fully qualified function name or a CODEREF to
$obj->keysort.

If you give any integers (excluded 0), the sort function will work as:

 sub { $a cmp $b }

Note that since the sort function is external to the JSON module the
magical $a and $b arguments will not be in the same package.  In order
to gain access to the sorting arguments, you must either:

  o use the ($$) prototype (slow)
  o Fully qualify $a and $b from the JSON::Converter namespace

See the documentation on sort for more information.

 local $JSON::KeySort = 'My::Package::sort_function';

 or

 local $JSON::KeySort = \&_some_function;

 sub sort_function {
    $JSON::Converter::a cmp $JSON::Converter::b;
 }

 or

 sub sort_function ($$) {
    my ($a, $b) = @_;

    $a cmp $b
 }

=head2 BLESSED OBJECT

By default, JSON::PC doesn't deal with any blessed object
(returns C<undef> or C<null> in the JSON format).
If you use $JSON::ConvBlessed or C<convblessed> option,
the module can convert most blessed object (hashref or arrayref).

If you use C<selfconvert> option,
the module will test for a C<toJson()> method on the object,
and will rely on this method to obtain the converted value of
the object.

=head2 UTF8

You can set a true(integer) for JSON::PC
to set UTF8 flag into strings contain utf8.
By default true.


=head2 CONVERT WITH SINGLE QUOTES

You can set a true(integer) for JSON::PC
to quote any keys and values with single quotations.

You want to parse single quoted JSON data, See L</SINGLE QUOTATION OPTION>.


=head1 TODO

These XS codes are very very dirty and should be cleaned up.

I wish to support some version less than Perl 5.8.

Should improve parse error message.

Tied variable is supported?

Test!

=head1 SEE ALSO

L<JSON>, L<JSON::Converter>, L<JSON::Parser>

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]donzoko.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
