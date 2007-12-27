
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define JSON_PC  1;

#define PARSER_NAME             "JSON::PC"
#define CONVERTER_NAME          "JSON::PC"
#define NOTSTRING_NAME          "JSON::NotString"
#define CONVERTER_SORT_NAME     "JSON::Converter::_sort_key"
#define PARSER_CHR_ROUTINE      "JSON::PC::Parser::_chr"

#define CONVERTER_DEFAULT_SORT_ROUTINE                          \
    (eval_pv("package JSON::Converter; sub { $a cmp $b }", 0))   


#define STR_BUFFER_SIZE     1024


#define IS_DIGIT(CH_PTR)                    \
    ((CH_PTR) >= '0' && (CH_PTR) <= '9')     


#define IS_HEX(CH_PTR)                          \
    (    IS_DIGIT(CH_PTR)                       \
      || ((CH_PTR) >= 'A' && (CH_PTR) <= 'F')   \
      || ((CH_PTR) >= 'a' && (CH_PTR) <= 'f')   \
    )                                            


/* parser api */

SV* json_parse (pTHX_ SV* self, SV* src, HV* opt);


/* converter api */
void jsonconv_boot(pTHX);
SV* json_convert  (pTHX_ SV* self, SV* data, HV* opt);
SV* json_convert2 (pTHX_ SV* self, SV* data, HV* opt);

