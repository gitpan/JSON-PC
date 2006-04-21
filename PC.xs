
#ifndef JSON_PC
#include "json_pc.h"
#endif

/*
    jsonparser_parse (obj, src, ...)
*/

MODULE = JSON::PC	PACKAGE = JSON::PC	PREFIX = jsonparser_

PROTOTYPES: DISABLE

SV*
jsonparser__parse (self, src, ...)
    SV*  src;
    SV*  self
PREINIT:
    HV*  opt;
    SV*  sv;
CODE:
    opt = items > 2 ? (HV*)SvRV(ST(2)) : (HV*)sv_2mortal((SV*)newHV());

    if (!SvOK(src)) {
        SvREFCNT_dec(src);
        src = newSVpv("", 0);
    }

    sv  = json_parse(aTHX_ self, src, opt);
    RETVAL = sv;
OUTPUT:
    RETVAL



MODULE = JSON::PC	PACKAGE = JSON::PC	PREFIX = jsonconv_

PROTOTYPES: DISABLE

SV*
jsonconv__convert (self, obj, ...)
    SV*  self
    SV*  obj
PREINIT:
    HV*  opt;
    SV*  sv;
CODE:
    opt = items > 2 ? (HV*)SvRV(ST(2)) : (HV*)sv_2mortal((SV*)newHV());
    sv  = json_convert(aTHX_ self, obj, opt);
    RETVAL = sv;
OUTPUT:
    RETVAL


SV*
jsonconv__toJson (self, obj)
    SV* self
    SV* obj
PREINIT:
    HV*  opt;
    SV*  sv;
CODE:
    opt = items > 2 ? (HV*)SvRV(ST(2)) : (HV*)sv_2mortal((SV*)newHV());
    sv  = json_convert(aTHX_ self, obj, opt);
    RETVAL = sv;
OUTPUT:
    RETVAL


SV*
jsonconv_valueToJson (self, obj)
    SV* self
    SV* obj
PREINIT:
    HV*  opt;
    SV*  sv;
CODE:
    opt = items > 2 ? (HV*)SvRV(ST(2)) : (HV*)sv_2mortal((SV*)newHV());
    sv  = json_convert2(aTHX_ self, obj, opt);
    RETVAL = sv;
OUTPUT:
    RETVAL


BOOT:
{
    jsonconv_boot(aTHX);
}
