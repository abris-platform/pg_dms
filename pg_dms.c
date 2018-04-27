#include "postgres.h"

#include "access/htup_details.h"
#include "access/tupdesc.h"
#include "access/xact.h"
#include "catalog/pg_type.h"
#include "executor/executor.h"
#include "fmgr.h"
#include "funcapi.h"
#include "miscadmin.h"
#include "utils/array.h"
#include "utils/builtins.h"
#include "utils/fmgrprotos.h"
#include "utils/json.h"
#include "utils/lsyscache.h"
#include "utils/syscache.h"
#include "utils/timestamp.h"
#include "utils/typcache.h"
#include "utils/uuid.h"

#include "pg_dms.h"

PG_MODULE_MAGIC;

//
//
//  id <-> status
//
//
PG_FUNCTION_INFO_V1(pg_dms_getstatus);
Datum pg_dms_getstatus(PG_FUNCTION_ARGS) {
    PG_RETURN_INT32((PG_GETARG_PGDMSID_P(0))->status);
};

PG_FUNCTION_INFO_V1(pg_dms_setstatus);
Datum pg_dms_setstatus(PG_FUNCTION_ARGS) {
    pg_dms_id *id = PG_GETARG_PGDMSID_P(0);
    id->status = PG_GETARG_INT32(1);
    PG_RETURN_POINTER(id);
};

//
//
//  id <-> action
//
//
PG_FUNCTION_INFO_V1(pg_dms_getaction);
Datum pg_dms_getaction(PG_FUNCTION_ARGS) {
    pg_dms_id *id = PG_GETARG_PGDMSID_P(0);
    int count = (VARSIZE(PG_GETARG_PGDMSID_P(0)) - sizeof(pg_dms_id)) / sizeof(action_t) + 1;
    TupleDesc itemTupleDesc = BlessTupleDesc(RelationNameGetTupleDesc("pg_dms_action_t"));
    int16 typlen;
    bool typbyval;
    char typalign;
    get_typlenbyvalalign(itemTupleDesc->tdtypeid, &typlen, &typbyval, &typalign);
    Datum *itemsArrayElements = (Datum *) palloc(sizeof(Datum) * count);
    for (int i = 0; i < count; i++) {
        Datum *itemValues = (Datum *) palloc(sizeof(Datum) * 5);
        itemValues[0] = Int32GetDatum(id->action[i].type);
        itemValues[1] = ObjectIdGetDatum(id->action[i].user);
        itemValues[2] = TimestampTzGetDatum(id->action[i].date);
        itemValues[3] = ObjectIdGetDatum(id->action[i].reason);
        itemValues[4] = UUIDPGetDatum(&id->action[i].reazon_key);
        bool *itemNulls = (bool *) palloc(sizeof(bool) * 5);
        itemNulls[0] = false;
        itemNulls[1] = false;
        itemNulls[2] = false;
        itemNulls[3] = id->action[i].reason ? false : true;
        itemNulls[4] = id->action[i].reason ? false : true;
        HeapTuple itemHeapTuple = heap_form_tuple(itemTupleDesc, itemValues, itemNulls);
        itemsArrayElements[i] = HeapTupleGetDatum(itemHeapTuple);
    }
    ArrayType *result = construct_array(itemsArrayElements, count, itemTupleDesc->tdtypeid, typlen, typbyval, typalign);
    PG_RETURN_ARRAYTYPE_P(result);
};

PG_FUNCTION_INFO_V1(pg_dms_setaction);
Datum pg_dms_setaction(PG_FUNCTION_ARGS) {
    pg_dms_id *id = PG_GETARG_PGDMSID_P(0);
    pg_dms_id *result = palloc(VARSIZE(id) + sizeof(action_t));
    memcpy(result, id, sizeof(pg_dms_id));
    SET_VARSIZE(result, VARSIZE(id) + sizeof(action_t));
    int num = (VARSIZE(result) - sizeof(pg_dms_id)) / sizeof(action_t);
    result->action[num].type = PG_GETARG_INT32(1);
    result->action[num].user = GetUserId();
    result->action[num].date = GetCurrentTransactionStartTimestamp();
    result->action[num].reason = PG_GETARG_OID(2);
    pg_uuid_t *a = PG_GETARG_UUID_P(3);
    result->action[num].reazon_key = *a;
    PG_RETURN_POINTER(result);
};

PG_FUNCTION_INFO_V1(pg_dms_test);
Datum pg_dms_test(PG_FUNCTION_ARGS) {
    HeapTupleHeader tuple = PG_GETARG_HEAPTUPLEHEADER(0);
    Oid tupType = HeapTupleHeaderGetTypeId(tuple);
    int32 tupTypmod = HeapTupleHeaderGetTypMod(tuple);
    TupleDesc tupDesc = lookup_rowtype_tupdesc(tupType, tupTypmod);
    AttInMetadata *attinmeta = TupleDescGetAttInMetadata(tupDesc);
    char *result = "";
    HeapTuple tableTypeTuple = SearchSysCache1(TYPEOID, ObjectIdGetDatum(tupDesc->tdtypeid));
    ReleaseSysCache(tableTypeTuple);
    result = psprintf("%s", pstrdup(NameStr(((Form_pg_type) GETSTRUCT(tableTypeTuple))->typname)));
    for (int i = 0; i < tupDesc->natts; i++) {
        if (TupleDescAttr(tupDesc, i)->attisdropped) {
            continue;
        }
        Form_pg_attribute att = TupleDescAttr(tupDesc, i);
        HeapTuple typeTuple = SearchSysCache1(TYPEOID, ObjectIdGetDatum(att->atttypid));
        char *name = pstrdup(NameStr(((Form_pg_type) GETSTRUCT(typeTuple))->typname));
        HeapTupleData tmptup;
        tmptup.t_len = HeapTupleHeaderGetDatumLength(tuple);
        ItemPointerSetInvalid(&(tmptup.t_self));
        tmptup.t_tableOid = InvalidOid;
        tmptup.t_data = tuple;
        bool isNull = false;
        Datum d = heap_getattr(&tmptup, att->attnum, tupDesc, &isNull);
        Oid typoutput;
        bool typIsVarlena;
        getTypeOutputInfo(attinmeta->attioparams[i], &typoutput, &typIsVarlena);
        char *value = !isNull ? OidOutputFunctionCall(typoutput, d) : "NULL";
        result = psprintf("%s %s:%s=%s", result, NameStr(att->attname), name, value);
        ReleaseSysCache(typeTuple);
    }
    ReleaseTupleDesc(tupDesc);
    PG_RETURN_TEXT_P(cstring_to_text(result));
}
