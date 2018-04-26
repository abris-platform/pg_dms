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
//  id
//
//
PG_FUNCTION_INFO_V1(pg_dms_id_in);
PG_FUNCTION_INFO_V1(pg_dms_id_out);
Datum
pg_dms_id_in(PG_FUNCTION_ARGS)
{
    //elog(NOTICE, "pg_dms_id_in(PG_FUNCTION_ARGS)");
    char         *str = PG_GETARG_CSTRING(0);
    if(strlen(str)!=73)
      ereport(ERROR, (errcode(ERRCODE_FEATURE_NOT_SUPPORTED), errmsg("key -%s is invalid", str)));
    pg_dms_id    *result = palloc(sizeof(pg_dms_id));

    SET_VARSIZE(result, sizeof(pg_dms_id));

    result->family = *DatumGetUUIDP(DirectFunctionCall1(uuid_in, CStringGetDatum(strtok (str, ","))));
    result->version = *DatumGetUUIDP(DirectFunctionCall1(uuid_in, CStringGetDatum(strtok (NULL, ","))));
    result->status = project;
    result->action[0].type = created;
    result->action[0].user = GetUserId();
    result->action[0].date = GetCurrentTransactionStartTimestamp();

    PG_RETURN_POINTER(result);
}
Datum
pg_dms_id_out(PG_FUNCTION_ARGS)
{
    pg_dms_id  *id = PG_GETARG_PGDMSID_P(0);
    char *f = DatumGetCString(DirectFunctionCall1(uuid_out, UUIDPGetDatum(&id->family)));
    char *v = DatumGetCString(DirectFunctionCall1(uuid_out, UUIDPGetDatum(&id->version)));
    char       *result = psprintf("%s,%s", f, v);
    PG_RETURN_CSTRING(result);
};
//
//
//  uuid -> id
//
//
PG_FUNCTION_INFO_V1(pg_dms_uuid2id);
Datum
pg_dms_uuid2id(PG_FUNCTION_ARGS)
{
    pg_uuid_t         *a = PG_GETARG_UUID_P(0);
    pg_dms_id    *result = palloc(sizeof(pg_dms_id));

    SET_VARSIZE(result, sizeof(pg_dms_id));

    result->family = *a;
    result->version = *a;
    result->status = project;
    result->action[0].type = created;
    result->action[0].user = GetUserId();
    result->action[0].date = GetCurrentTransactionStartTimestamp();

    PG_RETURN_POINTER(result);
}
//
//
//  id <-> id
//
//
PG_FUNCTION_INFO_V1(pg_dms_id_cmp);
PG_FUNCTION_INFO_V1(pg_dms_idgt);
PG_FUNCTION_INFO_V1(pg_dms_idge);
PG_FUNCTION_INFO_V1(pg_dms_ideq);
PG_FUNCTION_INFO_V1(pg_dms_idlt);
PG_FUNCTION_INFO_V1(pg_dms_idle); 
static int id_cmp (pg_dms_id *a, pg_dms_id *b)
{
    return memcmp(&(a->family), &(b->family),UUID_LEN*2);
}
Datum
pg_dms_id_cmp(PG_FUNCTION_ARGS)
{
    PG_RETURN_INT32(id_cmp(PG_GETARG_PGDMSID_P(0), PG_GETARG_PGDMSID_P(1)));
};
Datum
pg_dms_idgt(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(id_cmp(PG_GETARG_PGDMSID_P(0), PG_GETARG_PGDMSID_P(1))>0);
};
Datum
pg_dms_idge(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(id_cmp(PG_GETARG_PGDMSID_P(0), PG_GETARG_PGDMSID_P(1))>=0);
};
Datum
pg_dms_ideq(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(id_cmp(PG_GETARG_PGDMSID_P(0), PG_GETARG_PGDMSID_P(1))==0);
};
Datum
pg_dms_idle(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(id_cmp(PG_GETARG_PGDMSID_P(0), PG_GETARG_PGDMSID_P(1))<=0);
};
Datum
pg_dms_idlt(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(id_cmp(PG_GETARG_PGDMSID_P(0), PG_GETARG_PGDMSID_P(1))<0);
};
//
//
//  id <-> uuid
//
//
PG_FUNCTION_INFO_V1(pg_dms_iduuid_cmp);
PG_FUNCTION_INFO_V1(pg_dms_iduuidgt);
PG_FUNCTION_INFO_V1(pg_dms_iduuidge);
PG_FUNCTION_INFO_V1(pg_dms_iduuideq);
PG_FUNCTION_INFO_V1(pg_dms_iduuidlt);
PG_FUNCTION_INFO_V1(pg_dms_iduuidle); 
static int iduuid_cmp (pg_dms_id *a, pg_uuid_t *b)
{
    return memcmp(&(a->family), b,UUID_LEN);
}
Datum
pg_dms_iduuid_cmp(PG_FUNCTION_ARGS)
{
    PG_RETURN_INT32(iduuid_cmp(PG_GETARG_PGDMSID_P(0), PG_GETARG_UUID_P(1)));
};
Datum
pg_dms_iduuidgt(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(iduuid_cmp(PG_GETARG_PGDMSID_P(0), PG_GETARG_UUID_P(1))>0);
};
Datum
pg_dms_iduuidge(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(iduuid_cmp(PG_GETARG_PGDMSID_P(0), PG_GETARG_UUID_P(1))>=0);
};
Datum
pg_dms_iduuideq(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(iduuid_cmp(PG_GETARG_PGDMSID_P(0), PG_GETARG_UUID_P(1))==0);
};
Datum
pg_dms_iduuidle(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(iduuid_cmp(PG_GETARG_PGDMSID_P(0), PG_GETARG_UUID_P(1))<=0);
};
Datum
pg_dms_iduuidlt(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(iduuid_cmp(PG_GETARG_PGDMSID_P(0), PG_GETARG_UUID_P(1))<0);
};
//
//
//  uuid <-> id
//
//
PG_FUNCTION_INFO_V1(pg_dms_uuidid_cmp);
PG_FUNCTION_INFO_V1(pg_dms_uuididgt);
PG_FUNCTION_INFO_V1(pg_dms_uuididge);
PG_FUNCTION_INFO_V1(pg_dms_uuidideq);
PG_FUNCTION_INFO_V1(pg_dms_uuididlt);
PG_FUNCTION_INFO_V1(pg_dms_uuididle); 
static int uuidid_cmp (pg_uuid_t *a, pg_dms_id *b)
{
    return memcmp( a,&(b->family),UUID_LEN);
}
Datum
pg_dms_uuidid_cmp(PG_FUNCTION_ARGS)
{
    elog(NOTICE, "yra1");
    PG_RETURN_INT32(uuidid_cmp(PG_GETARG_UUID_P(0),PG_GETARG_PGDMSID_P(1)));
};
Datum
pg_dms_uuididgt(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(uuidid_cmp(PG_GETARG_UUID_P(0),PG_GETARG_PGDMSID_P(1))>0);
};
Datum
pg_dms_uuididge(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(uuidid_cmp(PG_GETARG_UUID_P(0),PG_GETARG_PGDMSID_P(1))>=0);
};
Datum
pg_dms_uuidideq(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(uuidid_cmp(PG_GETARG_UUID_P(0),PG_GETARG_PGDMSID_P(1))==0);
};
Datum
pg_dms_uuididle(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(uuidid_cmp(PG_GETARG_UUID_P(0),PG_GETARG_PGDMSID_P(1))<=0);
};
Datum
pg_dms_uuididlt(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(uuidid_cmp(PG_GETARG_UUID_P(0),PG_GETARG_PGDMSID_P(1))<0);
};
