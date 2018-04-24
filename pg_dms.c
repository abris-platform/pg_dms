#include "postgres.h"
#include "fmgr.h"
#include "utils/fmgrprotos.h"
#include "utils/uuid.h"
#include "utils/timestamp.h"
#include "access/xact.h"
#include "miscadmin.h"

PG_MODULE_MAGIC;
#define PG_GETARG_PGDMSID_P(n) (pg_dms_id *)DatumGetPointer(PG_GETARG_DATUM(n))
#define ACTION_USER_LEN 20

 



typedef enum ACTION_TYPE {
  created,  
  agreed,
  approved,
  rejected
} actiontype_t;

typedef struct {
    actiontype_t    type;
    Oid user;
    TimestampTz date;
} action_t;


typedef enum STATUS {
  project,
  document,
  archival
} status_t;


typedef struct pg_dms_id {
    char        vl_len_[4];
    pg_uuid_t   family;
    pg_uuid_t   version;
    status_t    status;
    action_t    action[1];
} pg_dms_id;

PG_FUNCTION_INFO_V1(pg_dms_id_in);
PG_FUNCTION_INFO_V1(pg_dms_id_out);
PG_FUNCTION_INFO_V1(pg_dms_id_recv);
PG_FUNCTION_INFO_V1(pg_dms_id_send);


Datum
pg_dms_id_in(PG_FUNCTION_ARGS)
{
    // elog(NOTICE, "pg_dms_id_in(PG_FUNCTION_ARGS)");
    // ereport(ERROR, (errcode(ERRCODE_FEATURE_NOT_SUPPORTED), errmsg("%d", sizeof(pg_dms_id))));

    char         *str = PG_GETARG_CSTRING(0);
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
Datum
pg_dms_id_recv(PG_FUNCTION_ARGS)
{
     elog(NOTICE, "pg_dms_id_recv");
    PG_RETURN_POINTER(NULL);
};
Datum
pg_dms_id_send(PG_FUNCTION_ARGS)
{
     elog(NOTICE, "pg_dms_id_send");
    PG_RETURN_BYTEA_P(NULL);
};


static int id_cmp (pg_dms_id *a, pg_dms_id *b)
{
    return memcmp(&(a->family), &(b->family),UUID_LEN*2);
}


PG_FUNCTION_INFO_V1(pg_dms_id_cmp);
PG_FUNCTION_INFO_V1(pg_dms_idgt);
PG_FUNCTION_INFO_V1(pg_dms_idge);
PG_FUNCTION_INFO_V1(pg_dms_ideq);
PG_FUNCTION_INFO_V1(pg_dms_idlt);
PG_FUNCTION_INFO_V1(pg_dms_idle);


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




PG_FUNCTION_INFO_V1(pg_dms_getstatus);
PG_FUNCTION_INFO_V1(pg_dms_setstatus);


Datum
pg_dms_getstatus(PG_FUNCTION_ARGS)
{
    PG_RETURN_INT32((PG_GETARG_PGDMSID_P(0))->status);
};
Datum
pg_dms_setstatus(PG_FUNCTION_ARGS)
{
  pg_dms_id  *id = PG_GETARG_PGDMSID_P(0);
  id->status = PG_GETARG_INT32(1);

  PG_RETURN_POINTER(id);
};


PG_FUNCTION_INFO_V1(pg_dms_getaction);
PG_FUNCTION_INFO_V1(pg_dms_setaction);
Datum
pg_dms_getaction(PG_FUNCTION_ARGS)
{
    pg_dms_id  *id = PG_GETARG_PGDMSID_P(0);
    int num = (VARSIZE(PG_GETARG_PGDMSID_P(0))-sizeof(pg_dms_id))/sizeof(action_t);
    char       *result;
    result = psprintf("(%d %s, %s)", id->action[0].type, GetUserNameFromId(id->action[0].user, true), timestamptz_to_str(id->action[0].date));
    for(int i=1; i<=num; i++){
       result = psprintf("%s, (%d %s %s)", result,  id->action[i].type, GetUserNameFromId(id->action[i].user, true), timestamptz_to_str(id->action[0].date));
    }
    PG_RETURN_CSTRING(result);
};

Datum
pg_dms_setaction(PG_FUNCTION_ARGS)
{
  pg_dms_id  *id = PG_GETARG_PGDMSID_P(0);

  pg_dms_id    *result = palloc(VARSIZE(id)+sizeof(action_t));
  memcpy(result, id, sizeof(pg_dms_id));
  SET_VARSIZE(result, VARSIZE(id)+sizeof(action_t));

  int num = (VARSIZE(result)-sizeof(pg_dms_id))/sizeof(action_t);
  result->action[num].type = PG_GETARG_INT32(1);
  result->action[num].user = GetUserId();
  result->action[num].date = GetCurrentTransactionStartTimestamp();
  PG_RETURN_POINTER(result);
};
