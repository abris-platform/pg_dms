#include "postgres.h"

#include "access/htup_details.h"
#include "access/tupdesc.h"
#include "catalog/pg_namespace.h"
#include "catalog/pg_type.h"
#include "common/md5.h"
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

#include "access/xact.h"

#include "pg_dms.h"

PG_MODULE_MAGIC;

//
//
//  id -> getstatus
//
//
PG_FUNCTION_INFO_V1(pg_dms_getstatus);
Datum pg_dms_getstatus(PG_FUNCTION_ARGS) {
    pg_dms_id *id = PG_GETARG_PGDMSID_P(0);
    int count = PG_DMS_ID_ACTIONS_COUNT(id);
    int status = 0;
    for (int i = 0; i < count; i++) {
        if (id->actions[i].type > status) {
            status = id->actions[i].type;
        }
    }
    PG_RETURN_INT32(status);
};
//
//
//  id -> getaction
//
//
PG_FUNCTION_INFO_V1(pg_dms_getaction);
Datum pg_dms_getaction(PG_FUNCTION_ARGS) {
    pg_dms_id *id = PG_GETARG_PGDMSID_P(0);
    int count = PG_DMS_ID_ACTIONS_COUNT(id);
    TupleDesc itemTupleDesc = BlessTupleDesc(RelationNameGetTupleDesc("pg_dms_action_t"));
    int16 typlen;
    bool typbyval;
    char typalign;
    get_typlenbyvalalign(itemTupleDesc->tdtypeid, &typlen, &typbyval, &typalign);
    Datum *itemsArrayElements = (Datum *) palloc(sizeof(Datum) * count);
    for (int i = 0; i < count; i++) {
        Datum *itemValues = (Datum *) palloc(sizeof(Datum) * 5);
        itemValues[0] = Int32GetDatum(id->actions[i].type);
        itemValues[1] = ObjectIdGetDatum(id->actions[i].user);
        itemValues[2] = TimestampTzGetDatum(id->actions[i].date);
        itemValues[3] = ObjectIdGetDatum(id->actions[i].reason);
        itemValues[4] = UUIDPGetDatum(&id->actions[i].reazon_key);
        bool *itemNulls = (bool *) palloc(sizeof(bool) * 5);
        itemNulls[0] = false;
        itemNulls[1] = false;
        itemNulls[2] = false;
        itemNulls[3] = id->actions[i].reason ? false : true;
        itemNulls[4] = id->actions[i].reason ? false : true;
        HeapTuple itemHeapTuple = heap_form_tuple(itemTupleDesc, itemValues, itemNulls);
        itemsArrayElements[i] = HeapTupleGetDatum(itemHeapTuple);
    }
    ArrayType *result = construct_array(itemsArrayElements, count, itemTupleDesc->tdtypeid, typlen, typbyval, typalign);
    PG_RETURN_ARRAYTYPE_P(result);
};
//
//
//  id -> setaction
//
//
PG_FUNCTION_INFO_V1(pg_dms_setaction);
Datum pg_dms_setaction(PG_FUNCTION_ARGS) {
    pg_dms_id *id = PG_GETARG_PGDMSID_P(0);
    pg_dms_id *result = palloc(VARSIZE(id) + sizeof(action_t));
    int count = PG_DMS_ID_ACTIONS_COUNT(id);
    memcpy(result, id, PG_DMS_ID_LENGTH(count));
    SET_VARSIZE(result, VARSIZE(id) + sizeof(action_t));
    result->actions[count].type = PG_GETARG_INT32(1);
    result->actions[count].user = GetUserId();
    result->actions[count].date = GetCurrentTransactionStartTimestamp();
    result->actions[count].reason = PG_GETARG_OID(2);
    result->actions[count].reazon_key = *PG_GETARG_UUID_P(3);
    PG_RETURN_POINTER(result);
};
//
//
//  id -> createversion
//
//
PG_FUNCTION_INFO_V1(pg_dms_createversion);
Datum pg_dms_createversion(PG_FUNCTION_ARGS) {
    pg_dms_id *result = palloc(sizeof(pg_dms_id));
    SET_VARSIZE(result, sizeof(pg_dms_id));
    result->family = (PG_GETARG_PGDMSID_P(0))->family;
    result->version = *(PG_GETARG_UUID_P(1));
    result->actions[0].type = ACTION_CREATED;
    result->actions[0].user = GetUserId();
    result->actions[0].date = GetCurrentTransactionStartTimestamp();
    PG_RETURN_POINTER(result);
}
//
//
//  pg_dms_getjson
//
//
PG_FUNCTION_INFO_V1(pg_dms_getjson);
Datum pg_dms_getjson(PG_FUNCTION_ARGS) {
    HeapTupleHeader record = PG_GETARG_HEAPTUPLEHEADER(0);
    Oid recordType = HeapTupleHeaderGetTypeId(record);
    TupleDesc recordDesc = lookup_rowtype_tupdesc(recordType, HeapTupleHeaderGetTypMod(record));
    HeapTuple tableTypeTuple = SearchSysCache1(TYPEOID, ObjectIdGetDatum(recordDesc->tdtypeid));
    HeapTuple tableTypeNamespaceTuple = SearchSysCache1(NAMESPACEOID, ObjectIdGetDatum(((Form_pg_type) GETSTRUCT(tableTypeTuple))->typnamespace));
    StringInfo result;
    pg_dms_id *id = PG_GETARG_PGDMSID_P(1);
    result = makeStringInfo();
    appendStringInfoString(result, "{");
    escape_json(result, "schema");
    appendStringInfoString(result, ": ");
    escape_json(result, NameStr(((Form_pg_namespace) GETSTRUCT(tableTypeNamespaceTuple))->nspname));
    appendStringInfoString(result, ", ");
    escape_json(result, "table");
    appendStringInfoString(result, ": ");
    escape_json(result, NameStr(((Form_pg_type) GETSTRUCT(tableTypeTuple))->typname));
    appendStringInfoString(result, ", ");
    escape_json(result, "key");
    appendStringInfoString(result, ": ");
    char *f = DatumGetCString(DirectFunctionCall1(uuid_out, UUIDPGetDatum(&id->family)));
    char *v = DatumGetCString(DirectFunctionCall1(uuid_out, UUIDPGetDatum(&id->version)));
    appendStringInfo(result, "\"%s,%s\"", f, v);
    appendStringInfoString(result, ", ");
    escape_json(result, "columns");
    appendStringInfoString(result, ": ");
    appendStringInfoString(result, "[");
    ReleaseSysCache(tableTypeTuple);
    ReleaseSysCache(tableTypeNamespaceTuple);
    AttInMetadata *attinmeta = TupleDescGetAttInMetadata(recordDesc);
    for (int i = 0; i < recordDesc->natts; i++) {
        if (TupleDescAttr(recordDesc, i)->attisdropped) {
            continue;
        }
        Form_pg_attribute att = TupleDescAttr(recordDesc, i);
        HeapTuple typecolumn = SearchSysCache1(TYPEOID, ObjectIdGetDatum(att->atttypid));
        char *type_str = pstrdup(NameStr(((Form_pg_type) GETSTRUCT(typecolumn))->typname));
        HeapTupleData tmptup;
        tmptup.t_len = HeapTupleHeaderGetDatumLength(record);
        ItemPointerSetInvalid(&(tmptup.t_self));
        tmptup.t_tableOid = InvalidOid;
        tmptup.t_data = record;
        bool isNull = false;
        Datum d = heap_getattr(&tmptup, att->attnum, recordDesc, &isNull);
        Oid typoutput;
        bool typIsVarlena;
        getTypeOutputInfo(attinmeta->attioparams[i], &typoutput, &typIsVarlena);
        char *value = !isNull ? OidOutputFunctionCall(typoutput, d) : NULL;
        if (i > 0) {
            appendStringInfoString(result, ", ");
        }
        appendStringInfoString(result, "{");
        escape_json(result, "name");
        appendStringInfoString(result, ": ");
        escape_json(result, NameStr(att->attname));
        appendStringInfoString(result, ", ");
        escape_json(result, "type");
        appendStringInfoString(result, ": ");
        escape_json(result, type_str);
        appendStringInfoString(result, ", ");
        escape_json(result, "value");
        appendStringInfoString(result, ": ");
        if (!isNull) {
            escape_json(result, value);
        } else {
            appendStringInfoString(result, "null");
        }
        appendStringInfoString(result, "}");
        if (!isNull) {
            pfree(value);
        }
        ReleaseSysCache(typecolumn);
    }
    ReleaseTupleDesc(recordDesc);
    appendStringInfoString(result, "]");
    int count = PG_DMS_ID_ACTIONS_COUNT(id);
    appendStringInfoString(result, ", ");
    escape_json(result, "actions");
    appendStringInfoString(result, ": ");
    appendStringInfoString(result, "[");
    for (int i = 0; i < count; i++) {
        if(id->actions[i].type < 0) continue;
        if (i > 0) {
            appendStringInfoString(result, ", ");
        }
        appendStringInfoString(result, "{");
        escape_json(result, "type");
        appendStringInfoString(result, ": ");
        appendStringInfo(result, "%d", id->actions[i].type);
        appendStringInfoString(result, ", ");
        escape_json(result, "user");
        appendStringInfoString(result, ": ");
        appendStringInfo(result, "%d", id->actions[i].user);
        appendStringInfoString(result, ", ");
        escape_json(result, "date");
        appendStringInfoString(result, ": ");
        escape_json(result, timestamptz_to_str(id->actions[i].date));
        appendStringInfoString(result, "}");
    }
    appendStringInfoString(result, "]");
    appendStringInfoString(result, "}");
    PG_RETURN_TEXT_P(cstring_to_text_with_len(result->data, result->len));
}
//
//
//  internal getStringForHash
//
void getStringForHash(HeapTupleHeader record, pg_dms_id *id, StringInfo result) {
    Oid recordType = HeapTupleHeaderGetTypeId(record);
    TupleDesc recordDesc = lookup_rowtype_tupdesc(recordType, HeapTupleHeaderGetTypMod(record));
    AttInMetadata *attinmeta = TupleDescGetAttInMetadata(recordDesc);
    for (int i = 0; i < recordDesc->natts; i++) {
        if (TupleDescAttr(recordDesc, i)->attisdropped) {
            continue;
        }
        Form_pg_attribute att = TupleDescAttr(recordDesc, i);
        HeapTupleData tmptup;
        tmptup.t_len = HeapTupleHeaderGetDatumLength(record);
        ItemPointerSetInvalid(&(tmptup.t_self));
        tmptup.t_tableOid = InvalidOid;
        tmptup.t_data = record;
        bool isNull = false;
        Oid typoutput;
        bool typIsVarlena;
        getTypeOutputInfo(attinmeta->attioparams[i], &typoutput, &typIsVarlena);
        char *value = !isNull ? OidOutputFunctionCall(typoutput, heap_getattr(&tmptup, att->attnum, recordDesc, &isNull)) : NULL;
        if (!isNull) {
            appendStringInfoString(result, value);
        }
        if (!isNull) {
            pfree(value);
        }
    }
    int count = PG_DMS_ID_ACTIONS_COUNT(id);
    for (int i = 0; i < count; i++) {
        if (id->actions[i].type >= 0) {
            appendStringInfo(result, "%d", id->actions[i].type);
            appendStringInfo(result, "%d", id->actions[i].user);
            appendStringInfo(result, "%s", timestamptz_to_str(id->actions[i].date));
        }
    }
    ReleaseTupleDesc(recordDesc);
}
//
//
//  pg_dms_getstringforhash
//
//
PG_FUNCTION_INFO_V1(pg_dms_getstringforhash);
Datum pg_dms_getstringforhash(PG_FUNCTION_ARGS) {
    HeapTupleHeader record = PG_GETARG_HEAPTUPLEHEADER(0);
    StringInfoData result;
    initStringInfo(&result);
    pg_dms_id *id = PG_GETARG_PGDMSID_P(1);
    getStringForHash(record, id, &result);
    PG_RETURN_TEXT_P(cstring_to_text_with_len(result.data, result.len));
}
//
//
//  gethash
//
//
PG_FUNCTION_INFO_V1(pg_dms_gethash);
Datum pg_dms_gethash(PG_FUNCTION_ARGS) {
    HeapTupleHeader record = PG_GETARG_HEAPTUPLEHEADER(0);
    StringInfoData result;
    initStringInfo(&result);
    pg_dms_id *id = PG_GETARG_PGDMSID_P(1);
    getStringForHash(record, id, &result);
    pg_uuid_t *hash = palloc(sizeof(pg_uuid_t));
    pg_md5_binary(result.data, result.len, (char *) hash->data);
    PG_RETURN_UUID_P(hash);
}
//
//
//  internal - findHash
//
//
bool findHash(pg_dms_id *id, unsigned char **hash) {
    int count = PG_DMS_ID_ACTIONS_COUNT(id);
    for (int i = 0; i < count; i++) {
        if (id->actions[i].type == ACTION_CALCULETED_HACH) {
            *hash = id->actions[i].reazon_key.data;
            return true;
        }
    }
    return false;
}
//
//
//  setHash
//
//
PG_FUNCTION_INFO_V1(pg_dms_sethash);
Datum pg_dms_sethash(PG_FUNCTION_ARGS) {
    pg_dms_id *id = PG_GETARG_PGDMSID_P(1);
    HeapTupleHeader record = PG_GETARG_HEAPTUPLEHEADER(0);
    StringInfoData str;
    initStringInfo(&str);
    getStringForHash(record, id, &str);

    pg_dms_id *result = palloc(VARSIZE(id) + sizeof(action_t));
    int count = PG_DMS_ID_ACTIONS_COUNT(id);
    memcpy(result, id, PG_DMS_ID_LENGTH(count));
    SET_VARSIZE(result, VARSIZE(id) + sizeof(action_t));
    result->actions[count].type = ACTION_CALCULETED_HACH;
    result->actions[count].user = GetUserId();
    result->actions[count].date = GetCurrentTransactionStartTimestamp();
    result->actions[count].reason = 0;
    pg_md5_binary(str.data, str.len, (char *) result->actions[count].reazon_key.data);

    PG_RETURN_POINTER(result);
}
//
//
//  pg_dms_checkHash
//
//
PG_FUNCTION_INFO_V1(pg_dms_checkhash);
Datum pg_dms_checkhash(PG_FUNCTION_ARGS) {
    pg_dms_id *id = PG_GETARG_PGDMSID_P(1);
    unsigned char *hash;
    
    if (!findHash(id, &hash)) {
        PG_RETURN_BOOL(false);
    }
    HeapTupleHeader record = PG_GETARG_HEAPTUPLEHEADER(0);
    StringInfoData str;
    initStringInfo(&str);
    getStringForHash(record, id, &str);

    unsigned char data[UUID_LEN];
    pg_md5_binary(str.data, str.len, &data);
    if (memcmp(hash, data, UUID_LEN) == 0) {
        PG_RETURN_BOOL(true);
    }
    PG_RETURN_BOOL(false);
}
//
//
//  id -> get_status_rigister
//
//
PG_FUNCTION_INFO_V1(get_status_rigister);
Datum get_status_rigister(PG_FUNCTION_ARGS) {
    pg_dms_id *id = PG_GETARG_PGDMSID_P(0);
    int count = PG_DMS_ID_ACTIONS_COUNT(id);
    int status = 0;
    for (int i = count-1; i >=0; i--) {
        if (id->actions[i].type == ACTION_ANSWER_RESPONSE) {
            status = 1;
            break;
        }
        if (id->actions[i].type == ACTION_SEND_REJISTER) {
            status = -1;
            break;
        }
    }
    PG_RETURN_INT32(status);
};

//
//
//  id -> getlevel
//
//
PG_FUNCTION_INFO_V1(pg_dms_getlevel);
Datum pg_dms_getlevel(PG_FUNCTION_ARGS) {
    pg_dms_id *id = PG_GETARG_PGDMSID_P(0);
    int count = PG_DMS_ID_ACTIONS_COUNT(id);
    long status = 0;
    int max = 0;
    for (int i = 0; i < count; i++) {
        if (id->actions[i].type == ACTION_APPROVED) {
            //Переводим разницу в минуты
            status = ((long)(GetCurrentTimestamp() - id->actions[i].date))/60000000l;
        }
        if (id->actions[i].type >= max) {
            max = id->actions[i].type;
        }
    }
    if(max < ACTION_APPROVED){
        status = INT_MAX;
    }
    //Для архивированных записей добавляем приблизительно 190 лет в минуты
    if(max > ACTION_APPROVED){
        status += 100000000;
    }
    PG_RETURN_INT32(status);
};
