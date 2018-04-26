#include "postgres.h"
#include "fmgr.h"
#include "utils/fmgrprotos.h"
#include "utils/uuid.h"
#include "utils/timestamp.h"

#include "utils/lsyscache.h"
#include "utils/builtins.h"
#include "utils/array.h"
#include "access/xact.h"
#include "access/htup_details.h"
#include "miscadmin.h"
#include "funcapi.h"
 
#include "pg_dms.h"

//
//
//  ref type
//
//
PG_FUNCTION_INFO_V1(pg_dms_ref_in);
PG_FUNCTION_INFO_V1(pg_dms_ref_out);
Datum
pg_dms_ref_in(PG_FUNCTION_ARGS)
{
    char         *str = PG_GETARG_CSTRING(0);
    if(strlen(str)!=73)
      ereport(ERROR, (errcode(ERRCODE_FEATURE_NOT_SUPPORTED), errmsg("key -%s is invalid", str)));
    pg_dms_ref    *result = palloc(sizeof(pg_dms_ref));
    result->family = *DatumGetUUIDP(DirectFunctionCall1(uuid_in, CStringGetDatum(strtok (str, ","))));
    result->version = *DatumGetUUIDP(DirectFunctionCall1(uuid_in, CStringGetDatum(strtok (NULL, ","))));
    PG_RETURN_POINTER(result);
}
Datum
pg_dms_ref_out(PG_FUNCTION_ARGS)
{
    pg_dms_ref  *ref = PG_GETARG_PGDMSREF_P(0);
    char *f = DatumGetCString(DirectFunctionCall1(uuid_out, UUIDPGetDatum(&ref->family)));
    char *v = DatumGetCString(DirectFunctionCall1(uuid_out, UUIDPGetDatum(&ref->version)));
    char       *result = psprintf("%s,%s", f, v);
    PG_RETURN_CSTRING(result);
};
//
//
//  ref <-> ref
//
//
PG_FUNCTION_INFO_V1(pg_dms_ref_cmp);
PG_FUNCTION_INFO_V1(pg_dms_refgt);
PG_FUNCTION_INFO_V1(pg_dms_refge);
PG_FUNCTION_INFO_V1(pg_dms_refeq);
PG_FUNCTION_INFO_V1(pg_dms_reflt);
PG_FUNCTION_INFO_V1(pg_dms_refle);
//
static int ref_cmp (pg_dms_ref *a, pg_dms_ref *b)
{
    return memcmp(&(a->family), &(b->family),UUID_LEN*2);
};
Datum
pg_dms_ref_cmp(PG_FUNCTION_ARGS)
{
    PG_RETURN_INT32(ref_cmp(PG_GETARG_PGDMSREF_P(0), PG_GETARG_PGDMSREF_P(1)));
};
Datum
pg_dms_refgt(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(ref_cmp(PG_GETARG_PGDMSREF_P(0), PG_GETARG_PGDMSREF_P(1))>0);
};
Datum
pg_dms_refge(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(ref_cmp(PG_GETARG_PGDMSREF_P(0), PG_GETARG_PGDMSREF_P(1))>=0);
};
Datum
pg_dms_refeq(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(ref_cmp(PG_GETARG_PGDMSREF_P(0), PG_GETARG_PGDMSREF_P(1))==0);
};
Datum
pg_dms_refle(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(ref_cmp(PG_GETARG_PGDMSREF_P(0), PG_GETARG_PGDMSREF_P(1))<=0);
};
Datum
pg_dms_reflt(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(ref_cmp(PG_GETARG_PGDMSREF_P(0), PG_GETARG_PGDMSREF_P(1))<0);
};
//
//
//  id <-> ref
//
//
PG_FUNCTION_INFO_V1(pg_dms_idref_cmp);
PG_FUNCTION_INFO_V1(pg_dms_idrefgt);
PG_FUNCTION_INFO_V1(pg_dms_idrefge);
PG_FUNCTION_INFO_V1(pg_dms_idrefeq);
PG_FUNCTION_INFO_V1(pg_dms_idreflt);
PG_FUNCTION_INFO_V1(pg_dms_idrefle); 
//
static int idref_cmp (pg_dms_id *a, pg_dms_ref *b)
{
    return memcmp(&(a->family), &(b->family), UUID_LEN*2);
}
Datum 
pg_dms_idref_cmp(PG_FUNCTION_ARGS)
{
    PG_RETURN_INT32(idref_cmp(PG_GETARG_PGDMSID_P(0), PG_GETARG_PGDMSREF_P(1)));
};
Datum 
pg_dms_idrefgt(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(idref_cmp(PG_GETARG_PGDMSID_P(0), PG_GETARG_PGDMSREF_P(1))>0);
};
Datum 
pg_dms_idrefge(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(idref_cmp(PG_GETARG_PGDMSID_P(0), PG_GETARG_PGDMSREF_P(1))>=0);
};
Datum 
pg_dms_idrefeq(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(idref_cmp(PG_GETARG_PGDMSID_P(0), PG_GETARG_PGDMSREF_P(1))==0);
};
Datum 
pg_dms_idrefle(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(idref_cmp(PG_GETARG_PGDMSID_P(0), PG_GETARG_PGDMSREF_P(1))<=0);
};
Datum 
pg_dms_idreflt(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(idref_cmp(PG_GETARG_PGDMSID_P(0), PG_GETARG_PGDMSREF_P(1))<0);
};
//
//
//  ref <-> id
//
//
PG_FUNCTION_INFO_V1(pg_dms_refid_cmp);
PG_FUNCTION_INFO_V1(pg_dms_refidgt);
PG_FUNCTION_INFO_V1(pg_dms_refidge);
PG_FUNCTION_INFO_V1(pg_dms_refideq);
PG_FUNCTION_INFO_V1(pg_dms_refidlt);
PG_FUNCTION_INFO_V1(pg_dms_refidle); 
static int refid_cmp (pg_dms_ref *a, pg_dms_id *b)
{
    return memcmp( &(a->family), &(b->family), UUID_LEN*2);
}
Datum
pg_dms_refid_cmp(PG_FUNCTION_ARGS)
{
    PG_RETURN_INT32(refid_cmp(PG_GETARG_PGDMSREF_P(0),PG_GETARG_PGDMSID_P(1)));
};
Datum
pg_dms_refidgt(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(refid_cmp(PG_GETARG_PGDMSREF_P(0),PG_GETARG_PGDMSID_P(1))>0);
};
Datum
pg_dms_refidge(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(refid_cmp(PG_GETARG_PGDMSREF_P(0),PG_GETARG_PGDMSID_P(1))>=0);
};
Datum
pg_dms_refideq(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(refid_cmp(PG_GETARG_PGDMSREF_P(0),PG_GETARG_PGDMSID_P(1))==0);
};
Datum
pg_dms_refidle(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(refid_cmp(PG_GETARG_PGDMSREF_P(0),PG_GETARG_PGDMSID_P(1))<=0);
};
Datum
pg_dms_refidlt(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(refid_cmp(PG_GETARG_PGDMSREF_P(0),PG_GETARG_PGDMSID_P(1))<0);
};
