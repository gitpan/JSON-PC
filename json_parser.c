
#ifndef JSON_PC
#include "json_pc.h"
#endif

typedef struct {
    SV*     self;           /* json parser object */
    char*   src;            /* json format string */
    int     c;              /* cahr cache */
    STRLEN  used;           /* parsed length */
    STRLEN  size;           /* string length */
    int     src_is_utf8;    /* source has UTF8 flag */
    char    err[512];       /* error message */
    /* parser option; see JSON doc */
    int     unmapping;
    int     barekey;
    int     quotapos;
    int     utf8;
} json_t;


#define GET_CHAR                                          \
    (json->used < json->size ?                            \
      (unsigned char) json->src[(json->used)++] : EOF)

#define PEEK_CHAR                                         \
    (json->used < json->size ?                            \
      (unsigned char) json->src[json->used] : EOF)


#define CHECK_STR_BUFFER_SIZE       \
    if (i == STR_BUFFER_SIZE) {     \
        str[i] = '\0';              \
        sv_catpv(obj, (char*)str);         \
        i = 0;                      \
    }                               \

/* size < 512 */
#define JSON_PARSE_ERROR(STR)       \
  if (!json->err[0])                \
        sprintf(json->err, STR)     \


SV*  json_value   (pTHX_ json_t* json);
SV*  json_member  (pTHX_ json_t* json);
SV*  json_array   (pTHX_ json_t* json);
SV*  json_string  (pTHX_ json_t* json);
SV*  json_number  (pTHX_ json_t* json);
SV*  json_word    (pTHX_ json_t* json);
SV*  json_bareKey (pTHX_ json_t* json);
void json_white   (pTHX_ json_t* json);
void _json_uchar  (pTHX_ UV uv, unsigned char* str, int* ip, SV* obj);
void _json_unicode(pTHX_ json_t* json, unsigned char* str, int* iptr, SV* obj);


/* Check all data type */

SV* json_value (pTHX_ json_t* json) {
    SV*  obj;

    json_white(aTHX_ json);

    switch (json->c) {
        case '"':
            obj = json_string(aTHX_ json);
            break;
        case '{':
            obj = json_member(aTHX_ json);
            break;
        case '[':
            obj = json_array(aTHX_ json);
            break;
        case '-':
            obj = json_number(aTHX_ json);
            break;
        case EOF:
            obj = &PL_sv_undef;
            break;
        default:
            if (json->c >= '0' && json->c <= '9') {
                obj = json_number(aTHX_ json);
            }
            else if (json->quotapos && json->c == '\'') {
                obj = json_string(aTHX_ json);
            }
            else {
                obj = json_word(aTHX_ json);
            }
            break;
    }

    return obj;
}

/* Skip comment or blank space */

void json_white (pTHX_ json_t* json) {

    while (json->c != EOF) {
        if(json->c <= ' '){
            json->c = GET_CHAR;
        }
        else if (json->c == '/') {
            json->c = GET_CHAR;
            if (json->c == '/') {
                json->c = GET_CHAR;
                while (json->c != EOF && json->c != '\n' && json->c != '\r') {
                    json->c = GET_CHAR;
                }
            }
            else if (json->c == '*') {
                json->c = GET_CHAR;
                while (1) {
                    if (json->c != EOF){
                        if (json->c == '*') {
                            json->c = GET_CHAR;
                            if( json->c != EOF && json->c == '/' ){
                                json->c = GET_CHAR;
                                break;
                            }
                        }
                        else{
                            json->c = GET_CHAR;
                        }
                    }
                    else{
                        JSON_PARSE_ERROR("Unterminated comment");
                        break;
                    }
                }
            }
            continue;
        }
        else{
            break;
        }
    }
}


SV* json_array (pTHX_ json_t* json) {
    AV*  ar;

    if(json->c == '['){
        ar = newAV();

        json->c = GET_CHAR;
        json_white(aTHX_ json);

        if (json->c == ']'){
            json->c = GET_CHAR;
            return newRV_noinc((SV*)ar);
        }

        while (json->c != EOF) {
            SV* obj = json_value(aTHX_ json);
            if (!obj)
                break;
            av_push(ar, obj);
            json_white(aTHX_ json);

            if (json->c == ']') {
                json->c = GET_CHAR;
                return newRV_noinc((SV*)ar);
            }
            else if (json->c != ',') {
                break;
            }
            json->c = GET_CHAR;
            json_white(aTHX_ json);
        }

    }

    SvREFCNT_dec(ar);
    JSON_PARSE_ERROR("Error in array");
    return FALSE;
}




SV* json_member (pTHX_ json_t* json) {
    HV*   hs;

    if(json->c == '{'){
        hs = newHV();

        json->c = GET_CHAR;
        json_white(aTHX_ json);

        if(json->c == '}'){
            json->c = GET_CHAR;
            return newRV_noinc((SV*)hs);
        }

        while (json->c != EOF) {
            SV*   key;
            SV*   val;

            if (json->barekey && json->c != '"' && json->c != '\''){
                key = json_bareKey(aTHX_ json);
            }
            else{
                key = json_string(aTHX_ json);
                if (!key) break;
            }

            json_white(aTHX_ json);

            if (json->c != ':'){
                SvREFCNT_dec(key);
                break;
            }

            json->c = GET_CHAR;

            val = json_value(aTHX_ json);
            hv_store_ent(hs, key, val, 0);

            SvREFCNT_dec(key);

            json_white(aTHX_ json);

            if(json->c == '}'){
                json->c = GET_CHAR;
                return newRV_noinc((SV*)hs);
            }
            else if (json->c != ',') {
                break;
            }

            json->c = GET_CHAR;
            json_white(aTHX_ json);
        }

    }

    SvREFCNT_dec(hs);
    JSON_PARSE_ERROR("Bad object");
    return FALSE;
}


SV* json_bareKey (pTHX_ json_t* json) {
    SV*  obj = newSVpv("",0);
    int  i = 0;
    int  c = json->c;
    unsigned char str[STR_BUFFER_SIZE];

    while (!(   (c >= 0  &&  c <= 35)
             || (c >= 37 &&  c <= 47)
             || (c >= 58 &&  c <= 64)
             || (c >= 91 &&  c <= 94)
             || (c == 96)
             || (c >= 123 &&  c <= 127)
            )
    ) {
        str[i++] = c;
        CHECK_STR_BUFFER_SIZE
        c = GET_CHAR;
    }

    json->c = c;
    str[i] = '\0';
    sv_catpv(obj, (char*)str);

    return obj;
}


SV* json_number (pTHX_ json_t* json) {
    SV*    obj;
    int    numtype;
    int    i = 0;
    char   str[STR_BUFFER_SIZE];

    if (json->c == '0') {
        int   c = GET_CHAR;
        int   hex     = 0;
        int   forward = 0;
        int   found   = 0;
        char  nstr[1024];

        STRLEN  len;
        I32     flag = 0;

        if (c == 'x' || c == 'X') {
            hex = 1;
            forward++;
            c = GET_CHAR;
        }

        while ( IS_HEX(c) ) {
            if (!found) found = 1;
            if (!hex && !(c >= '0' && c <= '7')) {
                forward++;
                found = 0;
                break;
            }
            nstr[ forward - hex ] = c;
            c = GET_CHAR;
            forward++;

            if(forward - hex > 1023) break;
        }

        if (found) {
            json->c = c;
            nstr[ forward - hex ] = '\0';

            len = (forward - hex);

            if (hex) {
                obj = newSVuv( grok_hex(nstr, &len, &flag, NULL) );
                return obj;
            }
            else {
                obj = newSVuv( grok_oct(nstr, &len, &flag, NULL) );
                return obj;
            }
        }
        else {
            /* restore */
            json->used -= (forward + 2 + hex);
            json->c = GET_CHAR;
        }
    }

    obj = newSVpv("",0);

    if (json->c == '-') {
        str[i++] = '-';
        json->c = GET_CHAR;
    }

    while ( IS_DIGIT(json->c) ) {
        str[i++] = json->c;
        json->c = GET_CHAR;
        CHECK_STR_BUFFER_SIZE
    }

    if (json->c == '.') {
        str[i++] = '.';
        json->c = GET_CHAR;
        CHECK_STR_BUFFER_SIZE

        while ( IS_DIGIT(json->c) ) {
            str[i++] = json->c;
            json->c = GET_CHAR;
            CHECK_STR_BUFFER_SIZE
        }
    }

    if (json->c == 'e' || json->c == 'E') {
        str[i++] = json->c;
        json->c = GET_CHAR;
        CHECK_STR_BUFFER_SIZE

        if (    json->c == '+'
             || json->c == '-'
             || (json->c >= '0' && json->c <= '9')
        ) {
            str[i++] = json->c;
            json->c = GET_CHAR;
            CHECK_STR_BUFFER_SIZE
        }

        while ( IS_DIGIT(json->c) ) {
            str[i++] = json->c;
            json->c = GET_CHAR;
            CHECK_STR_BUFFER_SIZE
        }

    }

    str[i] = '\0';
    sv_catpv(obj, str);

    numtype = grok_number(str, (STRLEN)strlen(str), NULL);

    //printf("%s is %d\n", str, numtype);

    if (numtype == 0) {
        return obj;
    }
    else if (numtype & IS_NUMBER_GREATER_THAN_UV_MAX) {
        return obj;
    }
    if (numtype & IS_NUMBER_NOT_INT) {
        NV num = SvNV(obj);
        SvREFCNT_dec(obj);
        return newSVnv(num);
    }
    else {
        IV integer = SvIV(obj);
        SvREFCNT_dec(obj);
        return newSViv(integer);
    }

}


SV* json_set_notstring (pTHX_ SV* word) {
    HV* hv    = newHV();
    HV* stash = gv_stashpv("JSON::NotString", 1);
    SV* rv;

    hv_store(hv, "value", 5, word, 0);
    rv = newRV_noinc((SV*)hv);
    sv_bless(rv, stash);

    return rv;
}


SV* json_word (pTHX_ json_t* json) {
    int  c = json->c;

    if ( strnEQ(&(json->src[json->used - 1]) , "null", 4) ) {
        SV* obj = json->unmapping
                 ? &PL_sv_undef
                 : json_set_notstring(aTHX_ &PL_sv_undef);
        json->used += 3;
        json->c = GET_CHAR;
        return obj;
    }
    else if ( strnEQ(&(json->src[json->used - 1]) , "true", 4) ) {
        SV* obj = json->unmapping
                 ? newSVpv("1", 0)
                 : json_set_notstring(aTHX_ newSVpv("true", 0));
        json->used += 3;
        json->c = GET_CHAR;
        return obj;
    }
    else if ( strnEQ(&(json->src[json->used - 1]) , "false", 5) ) {
        SV* obj = json->unmapping
                 ? newSVpv("0", 0)
                 : json_set_notstring(aTHX_ newSVpv("false", 0));
        json->used += 4;
        json->c = GET_CHAR;
        return obj;
    }

    JSON_PARSE_ERROR("Syntax error (word)");
    return FALSE;
}


SV* json_string (pTHX_ json_t* json) {
    SV*   obj = newSVpv("",0);
    int   boundChar;
    int   i = 0;
    unsigned char str[STR_BUFFER_SIZE];

    if ( json->c == '"' || (json->quotapos && json->c == '\'') ) {
        boundChar = json->c;

        while (1) {
            json->c = GET_CHAR;
            if (json->c == boundChar){
                json->c = GET_CHAR;
                str[i] = '\0';
                sv_catpv(obj, (char*)str);

                if (json->utf8 || json->src_is_utf8) {
                    SvUTF8_on(obj);
                }

                return obj;
            }
            else if (json->c == '\\') {
                json->c = GET_CHAR;
                switch (json->c) {
                    case 'b':
                        str[i++] = '\b';
                        break;
                    case 't':
                        str[i++] = '\t';
                        break;
                    case 'n':
                        str[i++] = '\n';
                        break;
                    case 'f':
                        str[i++] = '\f';
                        break;
                    case 'r':
                        str[i++] = '\r';
                        break;
                    case '\\':
                        str[i++] = '\\';
                        break;
                    case 'u':
                        _json_unicode(aTHX_ json, str, &i, obj);
                        break;
                    default:
                        str[i++] = json->c;
                        break;
                }
            }
            else if (json->c == EOF){
                break;
            }
            else {
                str[i++] = json->c;
            }

            CHECK_STR_BUFFER_SIZE
        }
    }

    SvREFCNT_dec(obj);
    JSON_PARSE_ERROR("Bad string");
    return FALSE;
}


void _json_unicode (pTHX_ json_t* json, unsigned char* str, int* iptr, SV* obj) {
    int     count;
    int     c;
    char    ustr[5];
    UV      uv;
    STRLEN  len  = 4;
    I32     flag = 0;

    for (count = 0; count < 4; count++) {
        c = GET_CHAR;

        if ( IS_HEX(c) ) {
            ustr[count] = c;
        }
        else {
            break;
        }
    }
    
    ustr[4] = '\0';
    uv = (UV)(grok_hex(ustr, &len, &flag, NULL));

    if (uv < 256) {
        str[(*iptr)++] = (int)uv;
    }
    else {
        _json_uchar(aTHX_ uv, str, iptr, obj);
    }


}


void _json_uchar (pTHX_ UV uv, unsigned char* str, int* ip, SV* obj) {
    int     count;
    SV*     sv;

    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVuv(uv)));
    PUTBACK;
    count = call_pv(PARSER_CHR_ROUTINE, G_SCALAR);

    SPAGAIN;

    if (count != 1)
       croak("Internal error : can't call _chr\n");

    sv = POPs;

    SvREFCNT_inc(sv);

    PUTBACK;
    FREETMPS;
    LEAVE;

    {
        STRLEN len;
        int    i;
        char*  chr = SvPV(sv, len);

        if (len + *ip >= STR_BUFFER_SIZE - 1) {
            str[*ip] = '\0';
            sv_catpv(obj, (char*)str);
            *ip = 0;
        }

        for (i = 0; i < (int)len; i++) {
            str[*ip + i] = *(chr + i);
        }

        *ip += len;

        SvREFCNT_dec(sv);
    }

    return;
}


void json_set_opt (pTHX_  HV* hv, HV* opt, int* pt, char* name, int len) {
    SV** svp = hv_fetch(hv, name, len, 0);

    *pt = (int)NULL;

    if ( svp ){
        *pt = (SvIOK(*svp)) ? SvIV(*svp) : 1;
    }

    if ((svp = hv_fetch(opt, name, len, 0)) && svp) {
        *pt = (SvIOK(*svp)) ? SvIV(*svp) : 1;
    }
    else {
        if (*pt == (int)NULL)
            *pt = 0;
    }
}


void json_init (pTHX_ json_t* json,  HV* opt) {
    HV*   hv = (HV*)SvRV(json->self);

    json_set_opt(aTHX_ hv, opt, &json->unmapping, "unmapping", 9);
    json_set_opt(aTHX_ hv, opt, &json->barekey,   "barekey",   7);
    json_set_opt(aTHX_ hv, opt, &json->quotapos,  "quotapos",  8);
    json_set_opt(aTHX_ hv, opt, &json->utf8,      "utf8",      4);

    return;
}


/* JSON::Parser::Fast's method */

SV* json_parse (pTHX_ SV* self, SV* src, HV* opt) {
    SV*      obj;
    json_t*  json;

    if ( !(SvROK(self) && sv_derived_from(self, PARSER_NAME)) )
        croak("parse is object method.");
    if ( SvTYPE(opt) != SVt_PVHV )
        croak("option must be hash reference.");

    json = (json_t *)PerlMemShared_malloc(sizeof(json_t));

    json->self = self;
    json->used = 0;
    json->src  = SvPV(src, json->size);
    json->c    = '\0';
    json->src_is_utf8 = SvUTF8(src) ? 1 : 0;
    json->err[0] = '\0';

    json_init(aTHX_ json, opt);

    obj = json_value(aTHX_ json);

    if (json->err[0]) {
        char err[1024];
        sprintf(err, json->err);
        PerlMemShared_free(json);
        croak(err);
    }

    PerlMemShared_free(json);

    return obj;
}


