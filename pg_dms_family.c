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
//  family type
//
//
PG_FUNCTION_INFO_V1(pg_dms_family_in);
PG_FUNCTION_INFO_V1(pg_dms_family_out);
Datum
pg_dms_family_in(PG_FUNCTION_ARGS)
{
    char         *str = PG_GETARG_CSTRING(0);
    pg_dms_family    *result = palloc(sizeof(pg_dms_family));
    result->family = *DatumGetUUIDP(DirectFunctionCall1(uuid_in, CStringGetDatum(strtok (str, ","))));
    PG_RETURN_POINTER(result);
}
Datum
pg_dms_family_out(PG_FUNCTION_ARGS)
{
    pg_dms_family  *id = PG_GETARG_PGDMSFAMILY_P(0);
    char *f = DatumGetCString(DirectFunctionCall1(uuid_out, UUIDPGetDatum(&id->family)));
    char       *result = psprintf("%s", f);
    PG_RETURN_CSTRING(result);
};
//
//
//  family uuid
//
//
PG_FUNCTION_INFO_V1(pg_dms_uuid2family);
Datum
pg_dms_uuid2family(PG_FUNCTION_ARGS)
{
    pg_uuid_t         *a = PG_GETARG_UUID_P(0);
    pg_dms_family    *result = palloc(sizeof(pg_dms_family));
    result->family = *a;
    PG_RETURN_POINTER(result);
}
//
//
//  family <-> family
//
//
PG_FUNCTION_INFO_V1(pg_dms_family_cmp);
PG_FUNCTION_INFO_V1(pg_dms_familygt);
PG_FUNCTION_INFO_V1(pg_dms_familyge);
PG_FUNCTION_INFO_V1(pg_dms_familyeq);
PG_FUNCTION_INFO_V1(pg_dms_familylt);
PG_FUNCTION_INFO_V1(pg_dms_familyle);
//
static int family_cmp (pg_dms_family *a, pg_dms_family *b)
{
    return memcmp(&(a->family), &(b->family),UUID_LEN);
};
Datum
pg_dms_family_cmp(PG_FUNCTION_ARGS)
{
    PG_RETURN_INT32(family_cmp(PG_GETARG_PGDMSFAMILY_P(0), PG_GETARG_PGDMSFAMILY_P(1)));
};
Datum
pg_dms_familygt(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(family_cmp(PG_GETARG_PGDMSFAMILY_P(0), PG_GETARG_PGDMSFAMILY_P(1))>0);
};
Datum
pg_dms_familyge(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(family_cmp(PG_GETARG_PGDMSFAMILY_P(0), PG_GETARG_PGDMSFAMILY_P(1))>=0);
};
Datum
pg_dms_familyeq(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(family_cmp(PG_GETARG_PGDMSFAMILY_P(0), PG_GETARG_PGDMSFAMILY_P(1))==0);
};
Datum
pg_dms_familyle(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(family_cmp(PG_GETARG_PGDMSFAMILY_P(0), PG_GETARG_PGDMSFAMILY_P(1))<=0);
};
Datum
pg_dms_familylt(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(family_cmp(PG_GETARG_PGDMSFAMILY_P(0), PG_GETARG_PGDMSFAMILY_P(1))<0);
};
//
//
//  id <-> family
//
//
PG_FUNCTION_INFO_V1(pg_dms_idfamily_cmp);
PG_FUNCTION_INFO_V1(pg_dms_idfamilygt);
PG_FUNCTION_INFO_V1(pg_dms_idfamilyge);
PG_FUNCTION_INFO_V1(pg_dms_idfamilyeq);
PG_FUNCTION_INFO_V1(pg_dms_idfamilylt);
PG_FUNCTION_INFO_V1(pg_dms_idfamilyle); 
//
static int idfamily_cmp (pg_dms_id *a, pg_dms_family *b)
{
    return memcmp(&(a->family), &(b->family), UUID_LEN);
}
Datum 
pg_dms_idfamily_cmp(PG_FUNCTION_ARGS)
{
    PG_RETURN_INT32(idfamily_cmp(PG_GETARG_PGDMSID_P(0), PG_GETARG_PGDMSFAMILY_P(1)));
};
Datum 
pg_dms_idfamilygt(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(idfamily_cmp(PG_GETARG_PGDMSID_P(0), PG_GETARG_PGDMSFAMILY_P(1))>0);
};
Datum 
pg_dms_idfamilyge(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(idfamily_cmp(PG_GETARG_PGDMSID_P(0), PG_GETARG_PGDMSFAMILY_P(1))>=0);
};
Datum 
pg_dms_idfamilyeq(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(idfamily_cmp(PG_GETARG_PGDMSID_P(0), PG_GETARG_PGDMSFAMILY_P(1))==0);
};
Datum 
pg_dms_idfamilyle(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(idfamily_cmp(PG_GETARG_PGDMSID_P(0), PG_GETARG_PGDMSFAMILY_P(1))<=0);
};
Datum 
pg_dms_idfamilylt(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(idfamily_cmp(PG_GETARG_PGDMSID_P(0), PG_GETARG_PGDMSFAMILY_P(1))<0);
};
//
//
//  family <-> id
//
//
PG_FUNCTION_INFO_V1(pg_dms_familyid_cmp);
PG_FUNCTION_INFO_V1(pg_dms_familyidgt);
PG_FUNCTION_INFO_V1(pg_dms_familyidge);
PG_FUNCTION_INFO_V1(pg_dms_familyideq);
PG_FUNCTION_INFO_V1(pg_dms_familyidlt);
PG_FUNCTION_INFO_V1(pg_dms_familyidle); 
static int familyid_cmp (pg_dms_family *a, pg_dms_id *b)
{
    return memcmp( &(a->family), &(b->family), UUID_LEN);
}
Datum
pg_dms_familyid_cmp(PG_FUNCTION_ARGS)
{
    PG_RETURN_INT32(familyid_cmp(PG_GETARG_PGDMSFAMILY_P(0),PG_GETARG_PGDMSID_P(1)));
};
Datum
pg_dms_familyidgt(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(familyid_cmp(PG_GETARG_PGDMSFAMILY_P(0),PG_GETARG_PGDMSID_P(1))>0);
};
Datum
pg_dms_familyidge(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(familyid_cmp(PG_GETARG_PGDMSFAMILY_P(0),PG_GETARG_PGDMSID_P(1))>=0);
};
Datum
pg_dms_familyideq(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(familyid_cmp(PG_GETARG_PGDMSFAMILY_P(0),PG_GETARG_PGDMSID_P(1))==0);
};
Datum
pg_dms_familyidle(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(familyid_cmp(PG_GETARG_PGDMSFAMILY_P(0),PG_GETARG_PGDMSID_P(1))<=0);
};
Datum
pg_dms_familyidlt(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(familyid_cmp(PG_GETARG_PGDMSFAMILY_P(0),PG_GETARG_PGDMSID_P(1))<0);
};
