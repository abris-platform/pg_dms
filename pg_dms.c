// #include <inttypes.h>

#include "postgres.h"
#include "fmgr.h"
#include "utils/fmgrprotos.h"
#include "utils/uuid.h"

#include "access/gist.h"
#include "access/stratnum.h"

PG_MODULE_MAGIC;


typedef struct pg_dms_d {
    char vl_len_[4];
    pg_uuid_t      family;
    pg_uuid_t      id;
} pg_dms_d;

PG_FUNCTION_INFO_V1(pg_dms_d_in);

Datum
pg_dms_d_in(PG_FUNCTION_ARGS)
{
    // elog(NOTICE, "pg_dms_d_in(PG_FUNCTION_ARGS)");
    // ereport(ERROR, (errcode(ERRCODE_FEATURE_NOT_SUPPORTED), errmsg("%d", sizeof(pg_dms_d))));
    char       *str = PG_GETARG_CSTRING(0);
    char *f = strtok (str, ",");
    char *i = strtok (NULL, ",");
    pg_uuid_t      family = *DatumGetUUIDP(DirectFunctionCall1(uuid_in, CStringGetDatum(f)));
    pg_uuid_t      id = *DatumGetUUIDP(DirectFunctionCall1(uuid_in, CStringGetDatum(i)));
    pg_dms_d    *result = palloc(sizeof(pg_dms_d));
    SET_VARSIZE(result, sizeof(pg_dms_d));
    result->family = family;
    result->id = id;
    PG_RETURN_POINTER(result);
}


PG_FUNCTION_INFO_V1(pg_dms_d_out);

Datum
pg_dms_d_out(PG_FUNCTION_ARGS)
{
    // elog(NOTICE, "pg_dms_d_out(PG_FUNCTION_ARGS)");
    // PG_RETURN_CSTRING("123456790");
    pg_dms_d    *did = (pg_dms_d *) PG_GETARG_POINTER(0);
    char *f = DatumGetCString(DirectFunctionCall1(uuid_out, UUIDPGetDatum(&did->family)));
    char *i = DatumGetCString(DirectFunctionCall1(uuid_out, UUIDPGetDatum(&did->id)));
    char       *result = psprintf("%s,%s", f, i);
    PG_RETURN_CSTRING(result);
}

