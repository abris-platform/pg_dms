\echo Use "CREATE EXTENSION pg_dms" to load this file. \quit

CREATE OPERATOR FAMILY pg_dms_ops USING btree;
--
--
--    id
--
--
CREATE FUNCTION pg_dms_id_in(cstring) RETURNS pg_dms_id AS 'pg_dms.so'  LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_id_out(pg_dms_id) RETURNS cstring AS 'pg_dms.so'  LANGUAGE C IMMUTABLE STRICT;

CREATE TYPE pg_dms_id (
   internallength = VARIABLE,
   input = pg_dms_id_in,      output = pg_dms_id_out,
   alignment = double
);
--
--
--    family
--
--
CREATE FUNCTION pg_dms_family_in(cstring) RETURNS pg_dms_family AS 'pg_dms.so'  LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_family_out(pg_dms_family)  RETURNS cstring AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;

CREATE TYPE pg_dms_family (
   internallength = 16,
   input = pg_dms_family_in, output = pg_dms_family_out,
   alignment = double
);
--
--
--    ref
--
--
CREATE FUNCTION pg_dms_ref_in(cstring) RETURNS pg_dms_ref AS 'pg_dms.so'  LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_ref_out(pg_dms_ref)  RETURNS cstring AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;

CREATE TYPE pg_dms_ref (
   internallength = 32,
   input = pg_dms_ref_in, output = pg_dms_ref_out,
   alignment = double
);
--
--
--    action_t
--
--
CREATE TYPE pg_dms_action_t AS (
    "type" integer,
    "user" Oid,
    "date" TimestampTz,
    "reason" Oid,
    "reason_key" uuid 
);
--
--
--    action_list
--
--
CREATE TABLE public.action_list (
  key integer NOT NULL,
  name text,
  CONSTRAINT d_action_list_pkey PRIMARY KEY (KEY)
)
WITH (OIDS = FALSE) TABLESPACE pg_default;

INSERT INTO public.action_list (KEY, name)  VALUES (0,   'Создано');
INSERT INTO public.action_list (KEY, name)  VALUES (100, 'Проверено');
INSERT INTO public.action_list (KEY, name)  VALUES (200, 'Утверждено');
INSERT INTO public.action_list (KEY, name)  VALUES (300, 'Архивировано');
INSERT INTO public.action_list (KEY, name)  VALUES (400, 'Отклонено');
INSERT INTO public.action_list (KEY, name)  VALUES (-10, 'Рассчитан хеш');
INSERT INTO public.action_list (KEY, name)  VALUES (-20, 'Направлено в реестр');
INSERT INTO public.action_list (KEY, name)  VALUES (-30, 'Добавлено в реестр');
--
--
--    id <-> id
--
--
CREATE FUNCTION pg_dms_id_cmp(pg_dms_id, pg_dms_id)  RETURNS int      AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_idgt  (pg_dms_id, pg_dms_id)  RETURNS boolean  AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_idge  (pg_dms_id, pg_dms_id)  RETURNS boolean  AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_ideq  (pg_dms_id, pg_dms_id)  RETURNS boolean  AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_idle  (pg_dms_id, pg_dms_id)  RETURNS boolean  AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_idlt  (pg_dms_id, pg_dms_id)  RETURNS boolean  AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR pg_catalog. >  (PROCEDURE = pg_dms_idgt, LEFTARG = pg_dms_id, RIGHTARG = pg_dms_id);
CREATE OPERATOR pg_catalog. >= (PROCEDURE = pg_dms_idge, LEFTARG = pg_dms_id, RIGHTARG = pg_dms_id);
CREATE OPERATOR pg_catalog. =  (PROCEDURE = pg_dms_ideq, LEFTARG = pg_dms_id, RIGHTARG = pg_dms_id);
CREATE OPERATOR pg_catalog. <= (PROCEDURE = pg_dms_idle, LEFTARG = pg_dms_id, RIGHTARG = pg_dms_id);
CREATE OPERATOR pg_catalog. <  (PROCEDURE = pg_dms_idlt, LEFTARG = pg_dms_id, RIGHTARG = pg_dms_id);

CREATE OPERATOR CLASS pg_dms_id DEFAULT FOR TYPE pg_dms_id
USING btree FAMILY pg_dms_ops AS 
  OPERATOR 1 <,
  OPERATOR 2 <=,
  OPERATOR 3 =,
  OPERATOR 4 >=,
  OPERATOR 5 >,
  FUNCTION 1 pg_dms_id_cmp(pg_dms_id, pg_dms_id);
--
--
--    id <-> uuid
--
--
CREATE FUNCTION pg_dms_iduuid_cmp(pg_dms_id, uuid) RETURNS int     AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_iduuidgt  (pg_dms_id, uuid) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_iduuidge  (pg_dms_id, uuid) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_iduuideq  (pg_dms_id, uuid) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_iduuidle  (pg_dms_id, uuid) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_iduuidlt  (pg_dms_id, uuid) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR pg_catalog.>  (PROCEDURE = pg_dms_iduuidgt, LEFTARG = pg_dms_id, RIGHTARG = uuid);
CREATE OPERATOR pg_catalog.>= (PROCEDURE = pg_dms_iduuidge, LEFTARG = pg_dms_id, RIGHTARG = uuid);
CREATE OPERATOR pg_catalog.=  (PROCEDURE = pg_dms_iduuideq, LEFTARG = pg_dms_id, RIGHTARG = uuid);
CREATE OPERATOR pg_catalog.<= (PROCEDURE = pg_dms_iduuidle, LEFTARG = pg_dms_id, RIGHTARG = uuid);
CREATE OPERATOR pg_catalog.<  (PROCEDURE = pg_dms_iduuidlt, LEFTARG = pg_dms_id, RIGHTARG = uuid);

ALTER OPERATOR FAMILY pg_dms_ops
USING btree  ADD 
  OPERATOR 1 <  (pg_dms_id, uuid),
  OPERATOR 2 <= (pg_dms_id, uuid),
  OPERATOR 3 =  (pg_dms_id, uuid),
  OPERATOR 4 >= (pg_dms_id, uuid),
  OPERATOR 5 >  (pg_dms_id, uuid),
  FUNCTION 1 public.pg_dms_iduuid_cmp (pg_dms_id, uuid);
--
--
--    uuid <-> id
--
--
CREATE FUNCTION pg_dms_uuidid_cmp (uuid, pg_dms_id) RETURNS int     AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_uuididgt   (uuid, pg_dms_id) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_uuididge   (uuid, pg_dms_id) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_uuidideq   (uuid, pg_dms_id) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_uuididle   (uuid, pg_dms_id) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_uuididlt   (uuid, pg_dms_id) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR pg_catalog. >  (PROCEDURE = pg_dms_uuididgt, LEFTARG = uuid, RIGHTARG = pg_dms_id);
CREATE OPERATOR pg_catalog. >= (PROCEDURE = pg_dms_uuididge, LEFTARG = uuid, RIGHTARG = pg_dms_id);
CREATE OPERATOR pg_catalog. =  (PROCEDURE = pg_dms_uuidideq, LEFTARG = uuid, RIGHTARG = pg_dms_id);
CREATE OPERATOR pg_catalog. <= (PROCEDURE = pg_dms_uuididle, LEFTARG = uuid, RIGHTARG = pg_dms_id);
CREATE OPERATOR pg_catalog. <  (PROCEDURE = pg_dms_uuididlt, LEFTARG = uuid, RIGHTARG = pg_dms_id);

ALTER OPERATOR FAMILY pg_dms_ops
USING btree ADD 
  OPERATOR 1 <  (uuid, pg_dms_id),
  OPERATOR 2 <= (uuid, pg_dms_id),
  OPERATOR 3 =  (uuid, pg_dms_id),
  OPERATOR 4 >= (uuid, pg_dms_id),
  OPERATOR 5 >  (uuid, pg_dms_id),
  FUNCTION 1    public.pg_dms_uuidid_cmp (uuid ,pg_dms_id);
--
--
--    family <-> family
--
--
CREATE FUNCTION pg_dms_family_cmp(pg_dms_family, pg_dms_family) RETURNS int     AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_familygt  (pg_dms_family, pg_dms_family) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_familyge  (pg_dms_family, pg_dms_family) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_familyeq  (pg_dms_family, pg_dms_family) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_familyle  (pg_dms_family, pg_dms_family) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_familylt  (pg_dms_family, pg_dms_family) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR pg_catalog. >  (PROCEDURE = pg_dms_familygt, LEFTARG = pg_dms_family, RIGHTARG = pg_dms_family);
CREATE OPERATOR pg_catalog. >= (PROCEDURE = pg_dms_familyge, LEFTARG = pg_dms_family, RIGHTARG = pg_dms_family);
CREATE OPERATOR pg_catalog. =  (PROCEDURE = pg_dms_familyeq, LEFTARG = pg_dms_family, RIGHTARG = pg_dms_family);
CREATE OPERATOR pg_catalog. <= (PROCEDURE = pg_dms_familyle, LEFTARG = pg_dms_family, RIGHTARG = pg_dms_family);
CREATE OPERATOR pg_catalog. <  (PROCEDURE = pg_dms_familylt, LEFTARG = pg_dms_family, RIGHTARG = pg_dms_family);

CREATE OPERATOR class pg_dms_family DEFAULT FOR TYPE pg_dms_family
USING btree FAMILY pg_dms_ops AS 
  OPERATOR 1 <,
  OPERATOR 2 <=,
  OPERATOR 3 =,
  OPERATOR 4 >=,
  OPERATOR 5 >,
  FUNCTION 1 public.pg_dms_family_cmp (pg_dms_family, pg_dms_family);
--
--
--    id <-> family
--
--
CREATE FUNCTION pg_dms_idfamily_cmp(pg_dms_id, pg_dms_family) RETURNS int     AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_idfamilygt  (pg_dms_id, pg_dms_family) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_idfamilyge  (pg_dms_id, pg_dms_family) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_idfamilyeq  (pg_dms_id, pg_dms_family) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_idfamilyle  (pg_dms_id, pg_dms_family) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_idfamilylt  (pg_dms_id, pg_dms_family) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR pg_catalog.>  (PROCEDURE = pg_dms_idfamilygt, LEFTARG = pg_dms_id, RIGHTARG = pg_dms_family);
CREATE OPERATOR pg_catalog.>= (PROCEDURE = pg_dms_idfamilyge, LEFTARG = pg_dms_id, RIGHTARG = pg_dms_family);
CREATE OPERATOR pg_catalog.=  (PROCEDURE = pg_dms_idfamilyeq, LEFTARG = pg_dms_id, RIGHTARG = pg_dms_family);
CREATE OPERATOR pg_catalog.<= (PROCEDURE = pg_dms_idfamilyle, LEFTARG = pg_dms_id, RIGHTARG = pg_dms_family);
CREATE OPERATOR pg_catalog.<  (PROCEDURE = pg_dms_idfamilylt, LEFTARG = pg_dms_id, RIGHTARG = pg_dms_family);

ALTER OPERATOR FAMILY pg_dms_ops
USING btree  ADD 
  OPERATOR 1 <  (pg_dms_id, pg_dms_family),
  OPERATOR 2 <= (pg_dms_id, pg_dms_family),
  OPERATOR 3 =  (pg_dms_id, pg_dms_family),
  OPERATOR 4 >= (pg_dms_id, pg_dms_family),
  OPERATOR 5 >  (pg_dms_id, pg_dms_family),
  FUNCTION 1    public.pg_dms_idfamily_cmp (pg_dms_id, pg_dms_family);
--
--
--    family <-> id
--
--
CREATE FUNCTION pg_dms_familyid_cmp (pg_dms_family, pg_dms_id) RETURNS int     AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_familyidgt   (pg_dms_family, pg_dms_id) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_familyidge   (pg_dms_family, pg_dms_id) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_familyideq   (pg_dms_family, pg_dms_id) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_familyidle   (pg_dms_family, pg_dms_id) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_familyidlt   (pg_dms_family, pg_dms_id) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR pg_catalog. >  (PROCEDURE = pg_dms_familyidgt, LEFTARG = pg_dms_family, RIGHTARG = pg_dms_id);
CREATE OPERATOR pg_catalog. >= (PROCEDURE = pg_dms_familyidge, LEFTARG = pg_dms_family, RIGHTARG = pg_dms_id);
CREATE OPERATOR pg_catalog. =  (PROCEDURE = pg_dms_familyideq, LEFTARG = pg_dms_family, RIGHTARG = pg_dms_id);
CREATE OPERATOR pg_catalog. <= (PROCEDURE = pg_dms_familyidle, LEFTARG = pg_dms_family, RIGHTARG = pg_dms_id);
CREATE OPERATOR pg_catalog. <  (PROCEDURE = pg_dms_familyidlt, LEFTARG = pg_dms_family, RIGHTARG = pg_dms_id);

ALTER OPERATOR FAMILY pg_dms_ops
USING btree ADD 
  OPERATOR 1 <  (pg_dms_family, pg_dms_id),
  OPERATOR 2 <= (pg_dms_family, pg_dms_id),
  OPERATOR 3 =  (pg_dms_family, pg_dms_id),
  OPERATOR 4 >= (pg_dms_family, pg_dms_id),
  OPERATOR 5 >  (pg_dms_family, pg_dms_id),
  FUNCTION 1    public.pg_dms_familyid_cmp (pg_dms_family ,pg_dms_id);
--
--
--    ref <-> ref
--
--
CREATE FUNCTION pg_dms_ref_cmp(pg_dms_ref, pg_dms_ref) RETURNS int     AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_refgt  (pg_dms_ref, pg_dms_ref) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_refge  (pg_dms_ref, pg_dms_ref) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_refeq  (pg_dms_ref, pg_dms_ref) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_refle  (pg_dms_ref, pg_dms_ref) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_reflt  (pg_dms_ref, pg_dms_ref) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR pg_catalog. >  (PROCEDURE = pg_dms_refgt, LEFTARG = pg_dms_ref, RIGHTARG = pg_dms_ref);
CREATE OPERATOR pg_catalog. >= (PROCEDURE = pg_dms_refge, LEFTARG = pg_dms_ref, RIGHTARG = pg_dms_ref);
CREATE OPERATOR pg_catalog. =  (PROCEDURE = pg_dms_refeq, LEFTARG = pg_dms_ref, RIGHTARG = pg_dms_ref);
CREATE OPERATOR pg_catalog. <= (PROCEDURE = pg_dms_refle, LEFTARG = pg_dms_ref, RIGHTARG = pg_dms_ref);
CREATE OPERATOR pg_catalog. <  (PROCEDURE = pg_dms_reflt, LEFTARG = pg_dms_ref, RIGHTARG = pg_dms_ref);

CREATE OPERATOR class pg_dms_ref DEFAULT FOR TYPE pg_dms_ref
USING btree FAMILY pg_dms_ops AS 
  OPERATOR 1 <,
  OPERATOR 2 <=,
  OPERATOR 3 =,
  OPERATOR 4 >=,
  OPERATOR 5 >,
  FUNCTION 1 public.pg_dms_ref_cmp (pg_dms_ref, pg_dms_ref);
--
--
--    id <-> ref
--
--
CREATE FUNCTION pg_dms_idref_cmp(pg_dms_id, pg_dms_ref) RETURNS int     AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_idrefgt  (pg_dms_id, pg_dms_ref) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_idrefge  (pg_dms_id, pg_dms_ref) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_idrefeq  (pg_dms_id, pg_dms_ref) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_idrefle  (pg_dms_id, pg_dms_ref) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_idreflt  (pg_dms_id, pg_dms_ref) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR pg_catalog.>  (PROCEDURE = pg_dms_idrefgt, LEFTARG = pg_dms_id, RIGHTARG = pg_dms_ref);
CREATE OPERATOR pg_catalog.>= (PROCEDURE = pg_dms_idrefge, LEFTARG = pg_dms_id, RIGHTARG = pg_dms_ref);
CREATE OPERATOR pg_catalog.=  (PROCEDURE = pg_dms_idrefeq, LEFTARG = pg_dms_id, RIGHTARG = pg_dms_ref);
CREATE OPERATOR pg_catalog.<= (PROCEDURE = pg_dms_idrefle, LEFTARG = pg_dms_id, RIGHTARG = pg_dms_ref);
CREATE OPERATOR pg_catalog.<  (PROCEDURE = pg_dms_idreflt, LEFTARG = pg_dms_id, RIGHTARG = pg_dms_ref);

ALTER OPERATOR FAMILY pg_dms_ops
USING btree  ADD 
  OPERATOR 1 <  (pg_dms_id, pg_dms_ref),
  OPERATOR 2 <= (pg_dms_id, pg_dms_ref),
  OPERATOR 3 =  (pg_dms_id, pg_dms_ref),
  OPERATOR 4 >= (pg_dms_id, pg_dms_ref),
  OPERATOR 5 >  (pg_dms_id, pg_dms_ref),
  FUNCTION 1    public.pg_dms_idref_cmp (pg_dms_id, pg_dms_ref);
--
--
--    ref <-> id
--
--
CREATE FUNCTION pg_dms_refid_cmp (pg_dms_ref, pg_dms_id) RETURNS int     AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_refidgt   (pg_dms_ref, pg_dms_id) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_refidge   (pg_dms_ref, pg_dms_id) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_refideq   (pg_dms_ref, pg_dms_id) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_refidle   (pg_dms_ref, pg_dms_id) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_refidlt   (pg_dms_ref, pg_dms_id) RETURNS boolean AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR pg_catalog. >  (PROCEDURE = pg_dms_refidgt, LEFTARG = pg_dms_ref, RIGHTARG = pg_dms_id);
CREATE OPERATOR pg_catalog. >= (PROCEDURE = pg_dms_refidge, LEFTARG = pg_dms_ref, RIGHTARG = pg_dms_id);
CREATE OPERATOR pg_catalog. =  (PROCEDURE = pg_dms_refideq, LEFTARG = pg_dms_ref, RIGHTARG = pg_dms_id);
CREATE OPERATOR pg_catalog. <= (PROCEDURE = pg_dms_refidle, LEFTARG = pg_dms_ref, RIGHTARG = pg_dms_id);
CREATE OPERATOR pg_catalog. <  (PROCEDURE = pg_dms_refidlt, LEFTARG = pg_dms_ref, RIGHTARG = pg_dms_id);

ALTER OPERATOR FAMILY pg_dms_ops
USING btree ADD 
  OPERATOR 1 <  (pg_dms_ref, pg_dms_id),
  OPERATOR 2 <= (pg_dms_ref, pg_dms_id),
  OPERATOR 3 =  (pg_dms_ref, pg_dms_id),
  OPERATOR 4 >= (pg_dms_ref, pg_dms_id),
  OPERATOR 5 >  (pg_dms_ref, pg_dms_id),
  FUNCTION 1    public.pg_dms_refid_cmp (pg_dms_ref ,pg_dms_id);
--
--
--    id extra
--
--
CREATE FUNCTION pg_dms_getstatus(pg_dms_id)                 RETURNS int               AS 'pg_dms.so'    LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_getaction(pg_dms_id)                 RETURNS pg_dms_action_t[] AS 'pg_dms.so'    LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_getlevel(pg_dms_id)                  RETURNS int               AS 'pg_dms.so'    LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_setaction(pg_dms_id, int, oid, uuid) RETURNS pg_dms_id         AS 'pg_dms.so'    LANGUAGE C IMMUTABLE STRICT;
--
--
--    uuid -> id
--
--
CREATE OR REPLACE FUNCTION public.pg_dms_uuid2id (uuid) RETURNS pg_dms_id AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE CAST(uuid AS pg_dms_id) WITH FUNCTION public.pg_dms_uuid2id (a uuid) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION public.pg_dms_createVersion    (pg_dms_id, uuid)   RETURNS pg_dms_id AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE OR REPLACE FUNCTION public.pg_dms_getjson          (record, pg_dms_id) RETURNS text      AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE OR REPLACE FUNCTION public.pg_dms_gethash          (record, pg_dms_id) RETURNS uuid      AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE OR REPLACE FUNCTION public.pg_dms_getStringForHash (record, pg_dms_id) RETURNS text      AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE OR REPLACE FUNCTION public.pg_dms_sethash          (record, pg_dms_id) RETURNS pg_dms_id AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE OR REPLACE FUNCTION public.pg_dms_checkhash        (record, pg_dms_id) RETURNS boolean   AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE OR REPLACE FUNCTION public.get_status_rigister     (pg_dms_id)         RETURNS integer   AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
--
--
--    record -> json
--
--
CREATE OR REPLACE FUNCTION pf_dms_insert_from_json (d json) RETURNS boolean LANGUAGE 'plpgsql' AS 
$BODY$
  DECLARE
    str text;
  BEGIN
    str = 'INSERT INTO ' || (d->>'schema')::text || '.' || (d->>'table')::text || 
      ' (' || (SELECT string_agg(concat.concat, ', ') FROM (SELECT "column"->>'name' AS concat FROM json_array_elements(d->'columns') AS "column") AS concat) || ') ' ||
      'VALUES (' || (SELECT string_agg(concat.concat, ', ') FROM (SELECT '''' || ("column"->>'value') || '''' AS concat FROM json_array_elements(d->'columns') AS "column") AS concat) || ')';
    EXECUTE str;
    RETURN true;
  END;
$BODY$;
--
--
--    register
--
--
CREATE TABLE public.register (
  "key" uuid NOT NULL DEFAULT uuid_generate_v4(),
  "data" json,
  "schema_name" text,
  "table_name" text,
  "column_key" text,
  "value_key" text,
  "inserted" TimestampTz DEFAULT now(),
  "status" integer DEFAULT 0,
  "num_register" uuid DEFAULT NULL,
  "ex_inserted" TimestampTz DEFAULT NULL,
  CONSTRAINT register_pkey PRIMARY KEY (KEY)
)
WITH (OIDS = FALSE) TABLESPACE pg_default;
--
--
--    record -> register
--
--
CREATE OR REPLACE FUNCTION pf_dms_insert_to_register (schema_name text, table_name text, column_key text, key pg_dms_id) 
RETURNS boolean LANGUAGE 'plpgsql' AS 
$BODY$
  DECLARE
    str text;
    data json;
    result uuid;
  BEGIN
    str = 'SELECT pg_dms_getjson (' || table_name || ', ' || column_key || ') FROM ' || 
       schema_name || '.' || table_name || ' WHERE ' || column_key || '=''' || key ||'''';
    EXECUTE str INTO data;

    str = 'INSERT INTO public.register (data, schema_name, table_name, column_key, value_key) VALUES (''' || 
      data || '''::json, ''' || schema_name || ''', ''' || table_name || ''', ''' || column_key || ''', ''' || key || ''') RETURNING key';
    EXECUTE str INTO result; 

    str = 'UPDATE ' || schema_name || '.' || table_name || ' SET '|| column_key ||
      ' = pg_dms_setaction(key, -20, ' || (SELECT oid FROM pg_class WHERE relname = 'register' LIMIT 1) || ', ''' || result || ''')'|| 
      ' WHERE ' || column_key || '=''' || key ||'''';
    EXECUTE str;

    RETURN true;
  END;
$BODY$;
--
--
--    update record 
--
--
CREATE OR REPLACE FUNCTION register_update_tf () 
RETURNS TRIGGER LANGUAGE 'plpgsql' AS 
$BODY$
  DECLARE
    str text;
  BEGIN
    str = 'UPDATE ' || new.schema_name || '.' || new.table_name || ' SET '|| new.column_key ||
      ' = pg_dms_setaction(key, -30, ' || (SELECT oid FROM pg_class WHERE relname = 'register' LIMIT 1) || ', ''' || new.num_register || ''')'|| 
      ' WHERE ' || new.column_key || '=''' || new.value_key ||'''';
    EXECUTE str;
    RETURN new;
  END;
$BODY$;
--
CREATE TRIGGER rigister_update_tr
    AFTER UPDATE 
    ON public.register
    FOR EACH ROW
    EXECUTE PROCEDURE public.register_update_tf();
--
--
--    register_file
--
--
CREATE TABLE public.register_file (
  "key" uuid NOT NULL DEFAULT uuid_generate_v4(),
  "file" json,
  "inserted" TimestampTz DEFAULT now(),
  "response_file" json,
  "status" integer DEFAULT 0,
  CONSTRAINT register_file_pkey PRIMARY KEY (KEY)
)
WITH (OIDS = FALSE) TABLESPACE pg_default;
--
--
--    register_file_update 
--
--
CREATE OR REPLACE FUNCTION register_file_update_tf () 
RETURNS TRIGGER LANGUAGE 'plpgsql' AS 
$BODY$
  DECLARE
    str json;
    x json;
  BEGIN
    IF new.response_file IS NOT NULL THEN
      FOR x IN SELECT * FROM json_array_elements(new.response_file)
      LOOP
        UPDATE public.register SET status=1, num_register=lpad(x->>'num_register', 32, '0')::uuid WHERE key = (x->>'local_key')::uuid;
      END LOOP;
    END IF;
    RETURN new;
  END;
$BODY$;
--
CREATE TRIGGER register_file_update_tr
    AFTER UPDATE 
    ON public.register_file
    FOR EACH ROW
    EXECUTE PROCEDURE public.register_file_update_tf();
--
--
--    create_file record_out 
--
--
CREATE OR REPLACE FUNCTION pf_dms_create_file  () 
RETURNS json LANGUAGE 'plpgsql' AS 
$BODY$
  DECLARE
    ret json;
  BEGIN
    INSERT INTO public.register_file (file) 
      VALUES ((SELECT jsonb_agg( json_build_object('local_key', r.key, 'data', r.data)) FROM register r where r.status = 0))
      RETURNING json_build_object('key_file', key, 'records', file) INTO ret; 
    RETURN ret;
  END;
$BODY$;
--
--
--    save response 
--
--
CREATE OR REPLACE FUNCTION pf_dms_save_response  (resp json) 
RETURNS boolean LANGUAGE 'plpgsql' AS 
$BODY$
  DECLARE
    ret json;
  BEGIN
    UPDATE public.register_file SET response_file = (resp->>'records')::json WHERE key =  (resp->>'local_file')::uuid;
    RETURN true;
  END;
$BODY$;
--
--
--    global_register_file
--
--
CREATE TABLE public.global_register_file (
  "key_file" uuid NOT NULL DEFAULT uuid_generate_v4(),
  "local_db" inet,
  "local_key" uuid,
  "local_file" json,
  "inserted" TimestampTz DEFAULT now(),
  "response_file" json,
  "status" integer DEFAULT 0,
  CONSTRAINT global_register_file_pkey PRIMARY KEY (key_file)
)
WITH (OIDS = FALSE) TABLESPACE pg_default;
--
--
--    global_register_file_insert 
--
--
CREATE OR REPLACE FUNCTION global_register_file_insert_tf () 
RETURNS TRIGGER LANGUAGE 'plpgsql' AS 
$BODY$
  DECLARE
    str json;
  BEGIN
    WITH inserted(num_register, local_key) AS (
      INSERT INTO public.global_register (local_key, table_name, schema_name, data, local_db)
        SELECT (record->>'local_key')::uuid AS local_key, 
                record->'data'->>'table' AS table_name, 
                record->'data'->>'schema' AS schema_name, 
                record->'data' AS data,
                new.local_db AS local_db
          FROM (SELECT json_array_elements(local_file->'records') AS record FROM public.global_register_file WHERE status = 0) AS record
        RETURNING num_register, local_key
    )
    SELECT jsonb_agg(json_build_object('local_key',local_key,'num_register',num_register)) FROM inserted INTO str;

    UPDATE public.global_register_file SET response_file = json_build_object('local_file',new.local_key, 'records', str);
    RETURN new;
  END;
$BODY$;
--
CREATE TRIGGER global_register_file_insert_tr
    AFTER INSERT 
    ON public.global_register_file
    FOR EACH ROW
    EXECUTE PROCEDURE public.global_register_file_insert_tf();
--
--
--    save_file record_out 
--
--
CREATE OR REPLACE FUNCTION pf_dms_save_file  (_ex_file json, _database inet) 
RETURNS boolean LANGUAGE 'plpgsql' AS 
$BODY$
  BEGIN
    INSERT INTO public.global_register_file (local_key, local_file, local_db) 
      VALUES ((_ex_file->>'key_file')::uuid, _ex_file,  _database);
    RETURN true;
  END;
$BODY$;
--
--
--    global_register 
--
--
CREATE SEQUENCE public.global_register_seq;
CREATE TABLE public.global_register (
  "num_register" integer NOT NULL DEFAULT nextval('global_register_seq'::regclass),
  "salt" uuid,
  "hash-block" uuid,
  "data" json,
  "local_key" uuid,
  "local_db" inet,
  "schema_name" text,
  "table_name" text,
  "inserted" TimestampTz DEFAULT now(),
  CONSTRAINT global_register_pkey PRIMARY KEY ("num_register")
)
WITH (OIDS = FALSE) TABLESPACE pg_default;
INSERT INTO public.global_register ("hash-block") VALUES('c60bf311-445a-40a4-9b4b-32e308789e66');
--
--
--    global_register 
--
--
CREATE OR REPLACE FUNCTION global_register_tf () 
RETURNS TRIGGER LANGUAGE 'plpgsql' AS 
$BODY$
  DECLARE
    prev_hash uuid;
  BEGIN
    SELECT "hash-block" FROM public.global_register WHERE num_register = (new.num_register -1) INTO prev_hash;
-- Обязательное условие - хеш должен начинаться с 000       
    LOOP
      new.salt = uuid_generate_v4();
      new."hash-block" = md5(new.data::text || prev_hash::text || new.salt::text );
      EXIT  WHEN substring(new."hash-block"::text,1,3) = '000';
    END LOOP;
    RETURN new;
  END;
$BODY$;

CREATE TRIGGER global_register_tr
    BEFORE INSERT 
    ON public.global_register
    FOR EACH ROW
    EXECUTE PROCEDURE public.global_register_tf();
