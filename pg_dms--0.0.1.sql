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

INSERT INTO public.action_list (KEY, name)  VALUES (0, 'Создано');
INSERT INTO public.action_list (KEY, name)  VALUES (1, 'Проверено');
INSERT INTO public.action_list (KEY, name)  VALUES (2, 'Утверждено');
INSERT INTO public.action_list (KEY, name)  VALUES (3, 'Архивировано');
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
USING btree family pg_dms_ops AS 
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
USING btree family pg_dms_ops AS 
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

ALTER OPERATOR family pg_dms_ops
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

ALTER OPERATOR family pg_dms_ops
USING btree ADD 
  OPERATOR 1 <  (pg_dms_family, pg_dms_id),
  OPERATOR 2 <= (pg_dms_family, pg_dms_id),
  OPERATOR 3 =  (pg_dms_family, pg_dms_id),
  OPERATOR 4 >= (pg_dms_family, pg_dms_id),
  OPERATOR 5 >  (pg_dms_family, pg_dms_id),
  FUNCTION 1    public.pg_dms_familyid_cmp (pg_dms_family ,pg_dms_id);
--
--
--    id extra
--
--
CREATE FUNCTION pg_dms_getstatus(pg_dms_id)      RETURNS int    AS 'pg_dms.so'    LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_setstatus(pg_dms_id, int) RETURNS pg_dms_id    AS 'pg_dms.so'    LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_getaction(pg_dms_id)      RETURNS pg_dms_action_t[]    AS 'pg_dms.so'    LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION pg_dms_setaction(pg_dms_id, int, oid, uuid)    RETURNS pg_dms_id    AS 'pg_dms.so'    LANGUAGE C IMMUTABLE STRICT;
--
--
--    uuid -> id
--
--
CREATE OR REPLACE FUNCTION public.pg_dms_uuid2id (uuid) RETURNS pg_dms_id AS 'pg_dms.so' LANGUAGE C IMMUTABLE STRICT;
CREATE CAST(uuid AS pg_dms_id) WITH FUNCTION public.pg_dms_uuid2id (a uuid) AS ASSIGNMENT;

