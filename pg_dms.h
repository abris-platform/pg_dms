#ifndef ___PG_DMS__
#define ___PG_DMS__

#include "postgres.h"

#include "fmgr.h"
#include "utils/fmgrprotos.h"
#include "utils/uuid.h"
#include "utils/timestamp.h"

#define PG_GETARG_PGDMSID_P(n) ((pg_dms_id *) DatumGetPointer(PG_GETARG_DATUM(n)))
#define PG_GETARG_PGDMSREF_P(n) ((pg_dms_ref *) DatumGetPointer(PG_GETARG_DATUM(n)))
#define PG_GETARG_PGDMSFAMILY_P(n) ((pg_dms_family *) DatumGetPointer(PG_GETARG_DATUM(n)))
#define ACTION_USER_LEN 20
#define PG_DMS_ID_ACTION_LENGHT(id) ((VARSIZE(id)-sizeof(pg_dms_id))/sizeof(action_t)+1)

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
    Oid reason;
    pg_uuid_t reazon_key;
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
    action_t    actions[1];
} pg_dms_id;

typedef struct pg_dms_family {
    pg_uuid_t   family;
} pg_dms_family;

typedef struct pg_dms_ref {
    pg_uuid_t   family;
    pg_uuid_t   version;
} pg_dms_ref;


#endif							/* ___PG_DMS__ */