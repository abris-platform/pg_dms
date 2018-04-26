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

PG_MODULE_MAGIC;

//
//
//  id <-> status
//
//
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
//
//
//  id <-> action
//
//
PG_FUNCTION_INFO_V1(pg_dms_getaction);
PG_FUNCTION_INFO_V1(pg_dms_setaction);
Datum
pg_dms_getaction(PG_FUNCTION_ARGS)
{
    pg_dms_id  *id = PG_GETARG_PGDMSID_P(0);
    int count = (VARSIZE(PG_GETARG_PGDMSID_P(0))-sizeof(pg_dms_id))/sizeof(action_t)+1;
    TupleDesc itemTupleDesc = BlessTupleDesc(RelationNameGetTupleDesc("pg_dms_action_t"));
    int16 typlen;
    bool typbyval;
    char typalign;
    get_typlenbyvalalign(itemTupleDesc->tdtypeid, &typlen, &typbyval, &typalign);
    Datum *itemsArrayElements = (Datum *)palloc(sizeof(Datum) * count);
    int i;
    for(i=0; i<count; i++){
        Datum *itemValues = (Datum *)palloc(sizeof(Datum) * 5);
        itemValues[0] = DatumGetInt32(id->action[i].type); 
        itemValues[1] = DatumGetObjectId(id->action[i].user);
        itemValues[2] = DatumGetTimestampTz(id->action[i].date);
        itemValues[3] = DatumGetObjectId(id->action[i].reason);
        itemValues[4] = DatumGetUUIDP(&id->action[i].reazon_key);
        bool *itemNulls = (bool *)palloc(sizeof(bool) * 5);
        itemNulls[0] = false;
        itemNulls[1] = false;
        itemNulls[2] = false;
        itemNulls[3] = id->action[i].reason?false:true;
        itemNulls[4] = id->action[i].reason?false:true;
        HeapTuple itemHeapTuple = heap_form_tuple(itemTupleDesc, itemValues, itemNulls);
        itemsArrayElements[i] = HeapTupleGetDatum(itemHeapTuple);
    }
    ArrayType *result = construct_array(itemsArrayElements, count, itemTupleDesc->tdtypeid, typlen, typbyval, typalign);
    PG_RETURN_ARRAYTYPE_P(result);
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
  result->action[num].reason = PG_GETARG_OID(2);
  pg_uuid_t  *a = PG_GETARG_UUID_P(3);
  result->action[num].reazon_key = *a;
  PG_RETURN_POINTER(result);
};
