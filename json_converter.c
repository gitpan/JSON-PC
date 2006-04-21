
#ifndef JSON_PC
#include "json_pc.h"
#endif

typedef struct {
    SV*     self;                   /* object itself */
    SV*     ptr;                    /* pointer to object */
    char    str[STR_BUFFER_SIZE];   /* json format string */
    int     pos;                    /* string pos counter */
    SV*     buf;                    /* string buffer */
    int     str_is_utf8;            /* string has UTF8 flag */
    /* converter option; see JSON doc */
    int     autoconv;
    int     execcoderef;
    int     skipinvalid;
    int     pretty;
    int     indent;
    int     delimiter;
    SV*     keysort;
    int     convblessed;
    int     selfconvert;
    int     utf8;
    int     singlequote;
    /* pretty */
    int     indent_count;
    char*   pre;
    char*   post;
} jsonconv_t;


/* JSON::Converter  */

void jsonconv_boot (pTHX);

/* Main process */
void json_convert_array (pTHX_ jsonconv_t* jv, AV* ar);
void json_convert_hash  (pTHX_ jsonconv_t* jv, HV* hv);
void json_stringfy      (pTHX_ jsonconv_t* jv, SV* pv);
void jsonconv_croak     (pTHX_ jsonconv_t* jv, char* message);

void jsonconv_call_selfToJSON (pTHX_ jsonconv_t* jv, SV* obj);

SV* jsonconv_end (pTHX_ jsonconv_t* jv);


/* check circulative reference */

static HV* seen_obj;


void jsonconv_boot (pTHX) {
    seen_obj = newHV();
    /* more? */
}




/* use jv */

#define JSONCONV_CHR(CHAR)                  \
    jv->str[(jv->pos++)] = CHAR;            \
    if (jv->pos == STR_BUFFER_SIZE) {       \
        jv->str[jv->pos] = '\0';            \
        sv_catpvf(jv->buf, "%s", jv->str);  \
        jv->pos = 0;                        \
    }                                       


#define JSONCONV_STR(STRING)                                        \
    {                                                               \
        int len  = strlen((STRING));                                \
        if (jv->pos + len > 1022) {                                 \
            jv->str[jv->pos] = '\0';                                \
            sv_catpvf(jv->buf, "%s", jv->str);                      \
            jv->pos = 0;                                            \
        }                                                           \
        sprintf(&(jv->str[jv->pos]), "%s", (STRING));               \
        jv->pos += len;                                             \
    }                                                               


#define JSON_NULL           \
    JSONCONV_STR("null")    \


#define CONVERT_REF                                            {\
    U32  datatype;                                              \
    SV*  rv  = SvRV(data);                                      \
    datatype = SvTYPE(rv);                                      \
    if (sv_derived_from(data, NOTSTRING_NAME)) {                \
        SV** svp = hv_fetch((HV*)rv, "value", 5, 0);            \
        if (svp)  {                                             \
            if (SvTYPE(*svp) == 0) {                            \
                JSON_NULL                                       \
            }                                                   \
            else{                                               \
                SV* tmp = newSVpv("", 0);                       \
                STRLEN clen;                                    \
                char*  ch;                                      \
                int i;                                          \
                sv_catsv(tmp, *svp);                            \
                ch = SvPV(tmp, clen);                           \
                for (i = 0; i < (int)clen; i++) {               \
                    JSONCONV_CHR( *(ch+i) );                    \
                }                                               \
                SvREFCNT_dec(tmp);                              \
            }                                                   \
        }                                                       \
        else {                                                  \
           JSON_NULL                                            \
        }                                                       \
    }                                                           \
    else if ( jv->selfconvert && sv_isobject(data) ){           \
        HV* stash = SvSTASH(SvRV(data));                        \
        if ( stash && gv_fetchmeth(stash, "toJson", 6, -1) )    \
            jsonconv_call_selfToJSON(aTHX_ jv, data);           \
    }                                                           \
    else if (jv->convblessed && sv_isobject(data)) {            \
        if (datatype == SVt_PVHV) {                             \
            json_convert_hash(aTHX_ jv, (HV*)rv);               \
        }                                                       \
        else if (datatype == SVt_PVAV) {                        \
            json_convert_array(aTHX_ jv, (AV*)rv);              \
        }                                                       \
    }                                                           \
    else if (!sv_isobject(data) && datatype == SVt_PVAV) {      \
        json_convert_array(aTHX_ jv, (AV*)rv);                  \
    }                                                           \
    else if (!sv_isobject(data) && datatype == SVt_PVHV) {      \
        json_convert_hash(aTHX_ jv, (HV*)rv);                   \
    }                                                           \
    else {                                                      \
        if (jv->execcoderef && datatype == SVt_PVCV) {          \
            jsonconv_eval(aTHX_ jv, data);                      \
        }                                                       \
        else {                                                  \
            if (jv->skipinvalid) {                              \
               JSON_NULL                                        \
            }                                                   \
            else {                                              \
                jsonconv_croak(aTHX_ jv, "Invalid value");      \
            }                                                   \
        }                                                       \
    }                                                           \
                                                               } 


#define CONVERT_SCALAR                                         {\
    U32  datatype = SvTYPE(data);                               \
    if (datatype == SVt_NULL) {                                 \
        JSON_NULL;                                              \
    }                                                           \
    else if (datatype == SVt_PV) {                              \
        json_stringfy (aTHX_ jv, data);                         \
    }                                                           \
    else if (datatype == SVt_IV) {                              \
        json_stringfy (aTHX_ jv, data);                         \
    }                                                           \
    else if (datatype == SVt_NV) {                              \
        json_stringfy (aTHX_ jv, data);                         \
    }                                                           \
    else if (datatype == SVt_PVIV || datatype == SVt_PVNV) {    \
        json_stringfy (aTHX_ jv, data);                         \
    }                                                           \
    else if (datatype == SVt_PVGV) {                            \
        /* JSON::Converter compatible */                        \
        json_stringfy (aTHX_ jv, data);                         \
    }                                                           \
    else {                                                      \
        if (jv->skipinvalid) {                                  \
           JSON_NULL                                            \
        }                                                       \
        else {                                                  \
            jsonconv_croak(aTHX_ jv, "Invalid value");          \
        }                                                       \
    }                                                           \
                                                               } 


#define CHECK_SEEN_OBJECT(target_obj)                       \
    IV   ptraddr = PTR2IV(SvRV(target_obj));                \
    SV*  seenkey = newSViv(ptraddr);                        \
    SV*  seen;                                              \
    HE*  check_he;                                          \
    check_he = hv_fetch_ent(seen_obj, jv->ptr, 0, 0);       \
    seen = HeVAL(check_he);                                 \
    if ( hv_exists_ent((HV*)seen, seenkey, 0) ) {           \
        jsonconv_croak(aTHX_ jv, "circle ref");             \
    }                                                       \
    else {                                                  \
        hv_store_ent((HV*)seen, seenkey, &PL_sv_yes, 0);    \
    }                                                       \


#define END_CHECK_SEEN_OBJECT                   \
    hv_delete_ent((HV*)seen, seenkey, 0, 0);    \
    SvREFCNT_dec(seenkey);                      \



void jsonconv_eval(pTHX_ jsonconv_t* jv, SV* cv) {
    SV* data;
    int count;

    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    PUTBACK;

    count = call_sv(cv, G_SCALAR);

    SPAGAIN;

    data = POPs;

    if (data) {
        SvREFCNT_inc(data);
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    if (data) {
        if (SvTYPE(data) == 0) {
            JSON_NULL;
        }
        else if ( SvROK(data) ) {
            CONVERT_REF;
        }
        else {
            CONVERT_SCALAR;
        }

        SvREFCNT_dec(data);
    }

    return;
}



int _json_autoconv_numeric (pTHX_ jsonconv_t* jv, char* ch, int len) {
    int ix    = 0;
    int found = 0;

    if(*(ch+ix) == '-')
        ix++;

    while (ix <= len){
        if ( IS_DIGIT(*(ch+ix)) ) {
            ix++;
            if (!found) found = 1;
        }
        else{
            break;
        }
    }

    if(*(ch+ix) == '.')
        ix++;

    while (ix <= len){
        if ( IS_DIGIT(*(ch+ix)) ) {
            ix++;
            if (!found) found = 1;
        }
        else{
            break;
        }
    }

    if (*(ch+ix) == 'e' || *(ch+ix) == 'E') {
        found = 0;
        ix++;
        if (*(ch+ix) == '+' || *(ch+ix) == '-') {
            ix++;
        }

        while (ix <= len){
            if ( IS_DIGIT(*(ch+ix)) ) {
                ix++;
                if (!found) found = 1;
            }
            else{
                break;
            }
        }

    }

    if (found && ix == len) {
        int i;
        for (i = 0; i < len; i++) {
            JSONCONV_CHR( *(ch+i) );
        }
        return 1;
    }

    return 0;
}


int _json_autoconv_hex (pTHX_ jsonconv_t* jv, char* ch, int len) {
    int ix    = 0;
    int found = 0;

    if(*(ch+ix) == '0' && (*(ch+ix+1) == 'X' || *(ch+ix+1) == 'x')){
        ix += 2;
    }
    else {
        return 0;
    }

    while (ix <= len){
        if ( IS_HEX(*(ch+ix)) ) {
            ix++;
            if (!found) found = 1;
        }
        else{
            break;
        }
    }

    if (found && ix == len) {
        int i;
        for (i = 0; i < len; i++) {
            JSONCONV_CHR( *(ch+i) );
        }
        return 1;
    }

    return 0;
}


int _json_autoconv_bool (pTHX_ jsonconv_t* jv, char* ch, int len) {

    if (strEQ(ch, "null")) {
        JSONCONV_STR("null");
        return 1;
    }

    if (strEQ(ch, "true")) {
        JSONCONV_STR("true");
        return 1;
    }

    if (strEQ(ch, "false")) {
        JSONCONV_STR("false");
        return 1;
    }

    return 0;
}


void json_stringfy (pTHX_ jsonconv_t* jv, SV* pv) {
    STRLEN  len;
    char*   ch;
    int     i;

    ch  = SvPV(pv, len);

    if ( SvUTF8(pv) ) {
        jv->str_is_utf8 = 1;
    }

    if (jv->autoconv) {
       if (_json_autoconv_numeric(aTHX_ jv, ch, (int)len)) return;
       if (_json_autoconv_hex(aTHX_ jv, ch, (int)len))     return;
       if (_json_autoconv_bool(aTHX_ jv, ch, (int)len))    return;
    }

    if (jv->singlequote) {
        JSONCONV_CHR( '\'' );
   }
    else {
        JSONCONV_CHR( '"' );
    }

    for (i = 0; i < (int)len; i++) {
        switch (*(ch+i)) {
            case '\\':
                JSONCONV_CHR( '\\' );
                JSONCONV_CHR( '\\' );
                break;
            case '\n':
                JSONCONV_CHR( '\\' );
                JSONCONV_CHR( 'n' );
                break;
            case '\r':
                JSONCONV_CHR( '\\' );
                JSONCONV_CHR( 'r' );
                break;
            case '\t':
                JSONCONV_CHR( '\\' );
                JSONCONV_CHR( 't' );
                break;
            case '\f':
                JSONCONV_CHR( '\\' );
                JSONCONV_CHR( 'f' );
                break;
            case '\b': 
                JSONCONV_CHR( '\\' );
                JSONCONV_CHR( 'b' );
                break;
            default:
                if (!jv->singlequote && *(ch+i) == '"') {
                    JSONCONV_CHR( '\\' );
                    JSONCONV_CHR( '"' );
                }
                else if (jv->singlequote && *(ch+i) == '\'') {
                    JSONCONV_CHR( '\\' );
                    JSONCONV_CHR( '\'' );
                }
                else if (*(ch+i) >= 0 && *(ch+i) < 32) {
                    char tmpstr[7];
                    sprintf(tmpstr, "\\u00%02x", *(ch+i));
                    tmpstr[6] = '\0';
                    JSONCONV_STR(tmpstr);
                }
                else {
                    JSONCONV_CHR( *(ch+i) );
                }
        }
    }

    if (jv->singlequote) {
        JSONCONV_CHR( '\'' );
    }
    else {
        JSONCONV_CHR( '"' );
    }

}


void jsonconv_pretty_pre(jsonconv_t* jv) {
    int   i;
    char  space[1024];

    if (jv->indent > 1023) {
        jv->indent = 1024;
    }

    for (i = 0; i < jv->indent; i++) {
        space[i]  = ' ';
    }

    space[jv->indent] = '\0';

    JSONCONV_CHR( '\n' );

    for (i = 0; i < jv->indent_count; i++) {
        int plus = sprintf(&(jv->str[jv->pos]), "%s", space);
        jv->pos += plus;
    }

    return;
}

void jsonconv_pretty_post(jsonconv_t* jv) {
    int   i;
    char  space[1024];

    if (jv->indent > 1023) {
        jv->indent = 1024;
    }

    for (i = 0; i < jv->indent; i++) {
        space[i]  = ' ';
    }

    space[jv->indent] = '\0';

    JSONCONV_CHR( '\n' );

    for (i = 0; i < jv->indent_count; i++) {
        int plus = sprintf(&(jv->str[jv->pos]), "%s", space);
        jv->pos += plus;
    }

    return;
}



void json_convert_array(pTHX_ jsonconv_t* jv, AV* ar) {
    I32  len = av_len(ar);
    I32  key;
    SV*  data;

    CHECK_SEEN_OBJECT(ar);

    JSONCONV_CHR( '[' );

    if (jv->pretty) {
        jv->indent_count++;
        jsonconv_pretty_pre(jv);
    }

    for (key = 0; key <= len; key++) {
        SV**  svp = av_fetch(ar, key, 0);
        if (!svp)
            croak("internal error in conv_array.");

        data = *svp;

        if ( SvROK(data) ) {
            CONVERT_REF
        }
        else {
            CONVERT_SCALAR
        }

        if (key != len) {
            JSONCONV_CHR( ',' );

            if (jv->pretty)
                jsonconv_pretty_pre(jv);
        }
    }

    END_CHECK_SEEN_OBJECT;

    if (jv->pretty) {
        jv->indent_count--;
        jsonconv_pretty_post(jv);
    }

    JSONCONV_CHR( ']' );
}



#define MAKE_JSON_MEMBER                            \
        json_stringfy (aTHX_ jv, key);              \
        if (jv->pretty && jv->delimiter) {          \
            if (jv->delimiter == 2) {               \
                JSONCONV_CHR( ' ' );                \
            }                                       \
            JSONCONV_CHR( ':' );                    \
            JSONCONV_CHR( ' ' );                    \
        }                                           \
        else {                                      \
            JSONCONV_CHR( ':' );                    \
        }                                           \
                                                    \
        if ( SvROK(data) ) {                        \
            CONVERT_REF                             \
        }                                           \
        else {                                      \
            CONVERT_SCALAR                          \
        }                                           \
                                                    \
        if (--num) {                                \
            JSONCONV_CHR( ',' );                    \
            if (jv->pretty)                         \
                jsonconv_pretty_pre(jv);            \
        }                                           \



AV* jsonconv_sort_key(pTHX_ AV* ar, SV* sub) {
    SV* rv    = newRV_inc((SV*)ar);
    AV* newar = newAV();

    int count;
    int i;

    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

    XPUSHs(sub);
    XPUSHs(rv);
    PUTBACK;

    count = call_pv(CONVERTER_SORT_NAME, G_ARRAY);

    SPAGAIN;

    av_extend(newar, count - 1);

    for (i = count - 1; i >= 0; i-- ) {
        SV* data = POPs;
        SvREFCNT_inc(data);
        av_store(newar, i, data);
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    SvREFCNT_dec(rv);

    return newar;
}


void json_convert_hash(pTHX_ jsonconv_t* jv, HV* hv) {
    HE*  he;
    I32  num;
    AV*  ar = NULL;    /* for sorting */

    CHECK_SEEN_OBJECT(hv);

    JSONCONV_CHR( '{' );

    num = hv_iterinit(hv);

    if (jv->keysort) {
        AV* tmpar = newAV();
        av_extend(tmpar, num - 1);

        while ( he = hv_iternext(hv) ) {
            SV* key = hv_iterkeysv(he);
            av_push(tmpar, key);
            SvREFCNT_inc(key);
        }
        ar = jsonconv_sort_key(aTHX_ tmpar, jv->keysort);

        SvREFCNT_dec(tmpar);
    }

    if (jv->pretty) {
        jv->indent_count++;
        jsonconv_pretty_pre(jv);
    }

    if (jv->keysort) {
        int idx;
        int maxidx = av_len(ar);

        for (idx = 0; idx <= maxidx; idx++) {
            STRLEN len3;
            SV*    key   = *av_fetch(ar, idx, 0);
            char*  kchar = SvPV(key, len3);
            SV*    data;

            if (hv_exists(hv, kchar, len3)) {
                data  = *hv_fetch(hv, kchar, len3, 0);
            }
            else {
                continue;
            }
            MAKE_JSON_MEMBER;
        }
    }
    else {
        while ( he = hv_iternext(hv) ) {
            SV* key  = hv_iterkeysv(he);
            SV* data = hv_iterval(hv, he);

            if (!key)
                croak("internal error in conv_hash.");

            MAKE_JSON_MEMBER;
        }
    }

    END_CHECK_SEEN_OBJECT;

    if (jv->pretty) {
        jv->indent_count--;
        jsonconv_pretty_post(jv);
    }

    if (ar)
        SvREFCNT_dec(ar);

    JSONCONV_CHR( '}' );
}


void josonconv_set_opt (pTHX_  HV* hv, HV* opt, int* pt, char* name, int len, char* Na) {
    SV** svp = hv_fetch(hv, name, len, 0);
    SV*  sv  = get_sv(Na, 0);

    *pt = 0;

    /* global JSON variables  */
    if (!svp || SvTYPE(*svp) == 0){
        if (sv && SvIOK(sv))
            *pt = SvIV(sv);
    } /* $self hash values */
    else if (SvIOK(*svp)) {
            *pt = SvIV(*svp);
    }

    if (SvTYPE(opt) != SVt_PVHV)
        croak("error");
    /* set option hash data (if any) */

    if ( (svp = hv_fetch(opt, name, len, 0)) && svp ){
        if (SvIOK(*svp)) {
            *pt = SvIV(*svp);
        }
    }

}


void josonconv_set_sort (pTHX_  HV* hv, HV* opt, SV** pt, char* name, int len, char* Na) {
    SV**  selfp = hv_fetch(hv, name, len, 0);
    SV*   sv    = get_sv(Na, 0);
    SV**  svp;

    *pt = NULL;

    if (!selfp || SvTYPE(*selfp) == 0){
        if (sv && SvTYPE(sv) == SVt_RV) {
            *pt = sv;
        }
        else if (sv && SvTYPE(sv) == SVt_PV) {
            *pt = sv;
        }
        else if (sv && SvIOK(sv)) {
            *pt = CONVERTER_DEFAULT_SORT_ROUTINE;
        }
    }
    else {
        if (SvROK(*selfp)) {
            *pt = *selfp;
        }
        else if (SvTYPE(*selfp) == SVt_PV) {
            *pt = sv;
        }
        else if (SvIOK(*selfp)) {
            *pt =CONVERTER_DEFAULT_SORT_ROUTINE;
        }
    }

    if (*pt)
        SvREFCNT_inc(*pt);

    /* set option hash data (if any) */
    if ( (svp = hv_fetch(opt, name, len, 0)) && *svp ){
        if (SvTYPE(*svp) == SVt_RV) {
            if (*pt) 
                SvREFCNT_dec(*pt);
            *pt = *svp;
            SvREFCNT_inc(*pt);
        }
        else if (SvIOK(*svp)) {
            if (*pt) 
                SvREFCNT_dec(*pt);
            *pt = CONVERTER_DEFAULT_SORT_ROUTINE;
            if (*pt)
            SvREFCNT_inc(*pt);
        }
    }
}




void jsonconv_call_selfToJSON (pTHX_ jsonconv_t* jv, SV* obj) {
    char* method = "toJson";
    SV*   data;
    int   count;

    CHECK_SEEN_OBJECT(obj);

    {

    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(obj);
    XPUSHs(jv->self);
    PUTBACK;

    count = call_method(method, G_SCALAR);
    if (count != 1)
        croak("Internal error while calling $obj->toJson");

    SPAGAIN;

    data = POPs;
    SvREFCNT_inc(data);

    PUTBACK;
    FREETMPS;
    LEAVE;

    }

    END_CHECK_SEEN_OBJECT;

    {
        int plus = sprintf(&(jv->str[jv->pos]), "%s", SvPV_nolen(data));
        jv->pos += plus;
    }

    return;
}


jsonconv_t* create_jsonconv (pTHX_ SV* self, HV* opt);


void jsonconv_init (pTHX_ jsonconv_t* jv,  HV* opt) {
    HV*  hv   = (HV*)SvRV(jv->self);

    josonconv_set_opt(aTHX_ hv, opt, &jv->utf8, "utf8", 4, "JSON::UTF8");
    josonconv_set_opt(aTHX_ hv, opt, &jv->autoconv, "autoconv", 8, "JSON::AUTOCONVERT");
    josonconv_set_opt(aTHX_ hv, opt, &jv->execcoderef, "execcoderef", 11, "JSON::ExecCoderef");
    josonconv_set_opt(aTHX_ hv, opt, &jv->skipinvalid, "skipinvalid", 11, "JSON::SkipInvalid");
    josonconv_set_opt(aTHX_ hv, opt, &jv->singlequote, "singlequote", 11, "JSON::SingleQuote");
    josonconv_set_opt(aTHX_ hv, opt, &jv->convblessed, "convblessed", 11, "JSON::ConvBlessed");
    josonconv_set_opt(aTHX_ hv, opt, &jv->selfconvert, "selfconvert", 11, "JSON::SelfConvert");

    josonconv_set_opt(aTHX_ hv, opt, &jv->pretty, "pretty", 6, "JSON::Pretty");
    josonconv_set_opt(aTHX_ hv, opt, &jv->indent, "indent", 6, "JSON::Indent");
    josonconv_set_opt(aTHX_ hv, opt, &jv->delimiter, "delimiter", 9, "JSON::Delimiter");

    josonconv_set_sort(aTHX_ hv, opt, &jv->keysort, "keysort", 7, "JSON::KeySort");

    jv->indent_count = 0;

    return;
}



jsonconv_t* create_jsonconv (pTHX_ SV* self, HV* opt) {
    jsonconv_t*  jv;

    if ( !(SvROK(self) && sv_derived_from(self, CONVERTER_NAME)) )
        croak("convert is object method.");
    if ( SvTYPE(opt) != SVt_PVHV )
        croak("option must be hash reference.");

    jv = (jsonconv_t *)PerlMemShared_malloc(sizeof(jsonconv_t));

    jv->buf     = newSVpvn("", 0);
    jv->str[0]  = '\0';
    jv->pos     = 0;
    jv->self    = self;
    jv->ptr     = newSViv(PTR2IV(SvRV(self)));
    jv->str_is_utf8 = 0;

    if ( !hv_exists_ent(seen_obj, jv->ptr, 0) ) {
        hv_store_ent(seen_obj, jv->ptr, (SV*)newHV(), 0);
    }

    jsonconv_init(aTHX_ jv, opt);

    return jv;
}



SV* json_convert (pTHX_ SV* self, SV* data, HV* opt) {
    jsonconv_t*  jv = create_jsonconv(aTHX_ self, opt);

    if (!data)
        return &PL_sv_undef;

    if ( jv->selfconvert && sv_isobject(data) ){
        HV* stash = SvSTASH(SvRV(data));
        if ( stash && gv_fetchmeth(stash, "toJson", 6, -1) )
            jsonconv_call_selfToJSON(aTHX_ jv, data);
        else
            return &PL_sv_undef;
    }
    else if ( !jv->convblessed && sv_isobject(data) ){
        return &PL_sv_undef;
    }
    else {
        if ( SvROK(data) ) {
            CONVERT_REF
        }
        else {
            return &PL_sv_undef;
        }
    }

    return jsonconv_end(aTHX_ jv);
}


SV* json_convert2 (pTHX_ SV* self, SV* data, HV* opt) {
    jsonconv_t*  jv = create_jsonconv(aTHX_ self, opt);

    if (!data)
        return &PL_sv_undef;

    {
        CONVERT_SCALAR;
    }

    return jsonconv_end(aTHX_ jv);
}




SV* jsonconv_end (pTHX_ jsonconv_t* jv) {
    SV*   obj;

    {
        HE* he = hv_fetch_ent(seen_obj, jv->ptr, 0, 0);
        HV* hv = (HV*)HeVAL(he);
        hv_clear(hv);
    }

    jv->str[jv->pos] = '\0';
    sv_catpvf(jv->buf, "%s", jv->str);

    obj = jv->buf;

    if (jv->utf8 || jv->str_is_utf8) {
        SvUTF8_on(obj);
    }

    if (jv->keysort)
        SvREFCNT_dec(jv->keysort);

    SvREFCNT_dec(jv->ptr);

    PerlMemShared_free(jv);

    return obj;
}


void jsonconv_croak(pTHX_ jsonconv_t* jv, char* message) {
    HE* he = hv_fetch_ent(seen_obj, jv->ptr, 0, 0);
    HV* hv = (HV*)HeVAL(he);
    hv_clear(hv);

    jv->buf = NULL;

    if (jv->keysort)
        SvREFCNT_dec(jv->keysort);

    PerlMemShared_free(jv);

    croak(message);
}
