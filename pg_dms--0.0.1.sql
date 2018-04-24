-- complain IF script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pg_dms" to load this file. \quit



CREATE FUNCTION pg_dms_id_in(cstring)
    RETURNS pg_dms_id
    AS 'pg_dms.so'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION pg_dms_id_out(pg_dms_id)
    RETURNS cstring
    AS 'pg_dms.so'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION pg_dms_id_recv(internal)
    RETURNS pg_dms_id
    AS 'pg_dms.so'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION pg_dms_id_send(pg_dms_id)
    RETURNS bytea
    AS 'pg_dms.so'
    LANGUAGE C IMMUTABLE STRICT;


CREATE TYPE pg_dms_id (
   internallength = VARIABLE,
   input = pg_dms_id_in,
   output = pg_dms_id_out,
   receive = pg_dms_id_recv,
   send = pg_dms_id_send,
   alignment = double
);
/*
CREATE TYPE pg_dms_action_t AS (
    "type" integer,
    "user" Oid,
    "date" TimestampTz 
);
*/
CREATE TYPE pg_dms_action_t AS (
    "type" integer,
    "user" Oid,
    "date" TimestampTz 
);

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


 
CREATE FUNCTION pg_dms_id_cmp(pg_dms_id, pg_dms_id)
    RETURNS int
    AS 'pg_dms.so'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION pg_dms_idgt(pg_dms_id, pg_dms_id)
    RETURNS boolean
    AS 'pg_dms.so'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION pg_dms_idge(pg_dms_id, pg_dms_id)
    RETURNS boolean
    AS 'pg_dms.so'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION pg_dms_ideq(pg_dms_id, pg_dms_id)
    RETURNS boolean
    AS 'pg_dms.so'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION pg_dms_idle(pg_dms_id, pg_dms_id)
    RETURNS boolean
    AS 'pg_dms.so'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION pg_dms_idlt(pg_dms_id, pg_dms_id)
    RETURNS boolean
    AS 'pg_dms.so'
    LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR pg_catalog. >  (PROCEDURE = pg_dms_idgt, LEFTARG = pg_dms_id, RIGHTARG = pg_dms_id);
CREATE OPERATOR pg_catalog. >= (PROCEDURE = pg_dms_idge, LEFTARG = pg_dms_id, RIGHTARG = pg_dms_id);
CREATE OPERATOR pg_catalog. =  (PROCEDURE = pg_dms_ideq, LEFTARG = pg_dms_id, RIGHTARG = pg_dms_id);
CREATE OPERATOR pg_catalog. <= (PROCEDURE = pg_dms_idle, LEFTARG = pg_dms_id, RIGHTARG = pg_dms_id);
CREATE OPERATOR pg_catalog. <  (PROCEDURE = pg_dms_idlt, LEFTARG = pg_dms_id, RIGHTARG = pg_dms_id);

CREATE OPERATOR CLASS pg_dms_id DEFAULT FOR TYPE pg_dms_id
USING btree --family pg_dms_ops
AS 
  OPERATOR 1 <,
  OPERATOR 2 <=,
  OPERATOR 3 =,
  OPERATOR 4 >=,
  OPERATOR 5 >,
FUNCTION 1 pg_dms_id_cmp(pg_dms_id, pg_dms_id);


CREATE FUNCTION pg_dms_getstatus(pg_dms_id)
    RETURNS int
    AS 'pg_dms.so'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION pg_dms_setstatus(pg_dms_id, int)
    RETURNS pg_dms_id
    AS 'pg_dms.so'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION pg_dms_getaction(pg_dms_id)
    RETURNS pg_dms_action_t[]
    AS 'pg_dms.so'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION pg_dms_setaction(pg_dms_id, int)
    RETURNS pg_dms_id
    AS 'pg_dms.so'
    LANGUAGE C IMMUTABLE STRICT;



/*
* FUNCTION pg_dms_get_pk (entity text)
*/
CREATE FUNCTION public.pg_dms_get_pk (entity text)
  RETURNS text
  LANGUAGE plpgsql IMMUTABLE STRICT
AS $BODY$
BEGIN
  RETURN (
    SELECT
      at.attname AS pk
    FROM
      pg_class r
    LEFT JOIN pg_namespace n ON n.oid = r.relnamespace
  LEFT JOIN pg_constraint c ON c.conrelid = r.oid
  AND c.contype = 'p'::char
  LEFT JOIN pg_attribute at ON c.conkey [ 1 ] = at.attnum
  AND at.attrelid = c.conrelid
WHERE (n.nspname || '.' || r.relname) = entity
LIMIT 1);
END;
$BODY$;

COMMENT ON FUNCTION public.pg_dms_get_pk (entity text)
IS 'Возвращает назване колонки содержащие первичный ключ.
                      entity - сущьность для которой ищется первичный ключ.';

/*
* TYPE pg_dms_actiontype
*/
CREATE TYPE public.pg_dms_actiontype AS ENUM ( 'created',
  'agreed',
  'approved',
  'rejected'
);

COMMENT ON TYPE public.pg_dms_actiontype IS 'Действия которые можно совершать с документами (строкой)';

/*
* FUNCTION public.pg_dms_to_text (a pg_dms_actiontype)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_to_text (a pg_dms_actiontype)
  RETURNS text
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  IF (a = 'created'::pg_dms_actiontype) THEN
    RETURN 'Создано';
  END IF;
  IF (a = 'agreed'::pg_dms_actiontype) THEN
    RETURN 'Согласовано';
  END IF;
  IF (a = 'approved'::pg_dms_actiontype) THEN
    RETURN 'Утверждено';
  END IF;
  IF (a = 'rejected'::pg_dms_actiontype) THEN
    RETURN 'Отклонено';
  END IF;
END;
$BODY$;

/*
* TYPE pg_dms_action
*/
CREATE TYPE public.pg_dms_action AS (
  created timestamp WITH time zone,
  usr text,
  act pg_dms_actiontype,
  note text
);

COMMENT ON TYPE public.pg_dms_actiontype IS 'Действиe которые совершено с документом (строкой)';

/*
* TYPE pg_dms_status
*/
CREATE TYPE public.pg_dms_status AS ENUM ( 'work',
  'project',
  'document',
  'archival'
);

COMMENT ON TYPE public.pg_dms_actiontype IS 'Состояние документа (строки)';

/*
* FUNCTION pg_dms_to_text (a pg_dms_status)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_to_text (a pg_dms_status)
  RETURNS text
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  IF (a = 'work'::pg_dms_status) THEN
    RETURN 'Материал';
  END IF;
  IF (a = 'project'::pg_dms_status) THEN
    RETURN 'Проект';
  END IF;
  IF (a = 'document'::pg_dms_status) THEN
    RETURN 'Документ';
  END IF;
  IF (a = 'archival'::pg_dms_status) THEN
    RETURN 'Архив';
  END IF;
END;
$BODY$;

/*
* FUNCTION pg_dms_to_text (a timestamp WITH time zone)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_to_text (a timestamp WITH time zone)
  RETURNS text
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN to_char(a, 'DD.MM.YY HH24:MI');
END;
$BODY$;

/*
* FUNCTION CAST pg_dms_to_text (a pg_dms_action)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_to_text (a pg_dms_action)
  RETURNS text
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN pg_dms_to_text ((a).created) || ' ' || pg_dms_to_text ((a).act) || ' ' || (a).usr || COALESCE(' (' || (a).note || ')',
    '');
END;
$BODY$;

/*
* CAST pg_dms_action => text
*/
CREATE CAST(
  pg_dms_action
AS text)
WITH FUNCTION public.pg_dms_to_text (pg_dms_action) AS ASSIGNMENT;
/*
* FUNCTION pg_dms_to_text (a pg_dms_action)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_to_text (a pg_dms_action [ ])
  RETURNS text
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
DECLARE
  ary ALIAS FOR $1;
  ret text;
BEGIN
  ret = ary [ 0 ]::text;
  FOR i IN 1..array_upper(ary,
    1)
  LOOP
    ret = ret || '; ' || ary [ i ]::text;
  END LOOP;
  RETURN ret;
END;
$BODY$;
/*
* OPERATOR family pg_dms_ops
*/
CREATE OPERATOR family pg_dms_ops
USING btree;
/*
-
-
-
* TYPE pg_dms_did
-
-
-
*/
CREATE TYPE public.pg_dms_did AS (
  family uuid,
  id uuid,
  status pg_dms_status,
  created timestamp WITH time zone,
  hash uuid,
  valid_from timestamp WITH time zone,
  valid_until timestamp WITH time zone,
  ac pg_dms_action [ ]
);
COMMENT ON TYPE public.pg_dms_actiontype IS 'Тип ключевого поля для документа (строки) в котором храниться вся информация и состоянии и действиях со строкой';
/*
* FUNCTION OPERATOR pg_dms_did_pg_dms_did_eq (a pg_dms_did, b pg_dms_did)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_did_pg_dms_did_eq (a pg_dms_did, b pg_dms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--100';
  RETURN a.id = b.id;
END;
$BODY$;
/*
* OPERATOR pg_dms_did = pg_dms_did
*/
CREATE OPERATOR pg_catalog. #=# (
PROCEDURE = pg_dms_did_pg_dms_did_eq, LEFTARG = pg_dms_did, RIGHTARG = pg_dms_did);
/*
* FUNCTION OPERATOR pg_dms_did_pg_dms_did_lt (a pg_dms_did, b pg_dms_did)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_did_pg_dms_did_lt (a pg_dms_did, b pg_dms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--101';
  RETURN a.id < b.id;
END;
$BODY$;
/*
* OPERATOR pg_dms_did < pg_dms_did
*/
CREATE OPERATOR pg_catalog. #<# (
PROCEDURE = pg_dms_did_pg_dms_did_lt, LEFTARG = pg_dms_did, RIGHTARG = pg_dms_did);
/*
* FUNCTION OPERATOR pg_dms_did_pg_dms_did_lt (a pg_dms_did, b pg_dms_did)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_did_pg_dms_did_le (a pg_dms_did, b pg_dms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--102';
  RETURN a.id <= b.id;
END;
$BODY$;
/*
* OPERATOR pg_dms_did <= pg_dms_did
*/
CREATE OPERATOR pg_catalog. #<=# (
PROCEDURE = pg_dms_did_pg_dms_did_le, LEFTARG = pg_dms_did, RIGHTARG = pg_dms_did);
/*
* FUNCTION OPERATOR pg_dms_did_pg_dms_did_lt (a pg_dms_did, b pg_dms_did)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_did_pg_dms_did_ge (a pg_dms_did, b pg_dms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--103';
  RETURN a.id >= b.id;
END;
$BODY$;
/*
* OPERATOR pg_dms_did >= pg_dms_did
*/
CREATE OPERATOR pg_catalog. #>=# (
PROCEDURE = pg_dms_did_pg_dms_did_ge, LEFTARG = pg_dms_did, RIGHTARG = pg_dms_did);
/*
* FUNCTION OPERATOR pg_dms_did_pg_dms_did_lt (a pg_dms_did, b pg_dms_did)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_did_pg_dms_did_gt (a pg_dms_did, b pg_dms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--104';
  RETURN a.id > b.id;
END;
$BODY$;
/*
* OPERATOR pg_dms_did > pg_dms_did
*/
CREATE OPERATOR pg_catalog. #># (
PROCEDURE = pg_dms_did_pg_dms_did_gt, LEFTARG = pg_dms_did, RIGHTARG = pg_dms_did);
/*
* FUNCTION OPERATOR pg_dms_did_pg_dms_did_lt (a pg_dms_did, b pg_dms_did)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_did_cmp (a pg_dms_did, b pg_dms_did)
  RETURNS integer
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--105';
  raise notice 'a.family % b.family %, a.id % b.id %', a.family, b.family, a.id, b.id;
  raise notice 'a.status % b.status %', a.status, b.status;

  IF (a.family < b.family) THEN
    RETURN - 1;
  END IF;
  IF (a.family > b.family) THEN
    RETURN 1;
  END IF;
  IF (a.family = b.family) THEN
    IF (a.id < b.id) THEN
      RETURN - 1;
    END IF;
    IF (a.id > b.id) THEN
      RETURN 1;
    END IF;
    IF (a.id = b.id) THEN
      --IF (a.status = a.status) THEN 
        RETURN 0;
      --ELSE
      --  RETURN -1;
      --END IF;
    END IF;
  END IF;
END;
$BODY$;
/*
* OPERATOR class pg_dms_did
*/
CREATE OPERATOR class pg_dms_did DEFAULT FOR TYPE pg_dms_did
USING btree family pg_dms_ops
AS OPERATOR 1 #<#,
OPERATOR 2 #<=#,
OPERATOR 3 #=#,
OPERATOR 4 #>=#,
OPERATOR 5 #>#,
FUNCTION 1 public.pg_dms_did_cmp (pg_dms_did,
  pg_dms_did);
/*
-
-
* TYPE pg_dms_family_ref
-
-
*/
CREATE TYPE public.pg_dms_family_ref AS (
  family uuid
);
COMMENT ON TYPE public.pg_dms_actiontype IS 'Тип поля зависимой таблицы котороый ссылается на таблицу с докуентами и зависит от изменений документа';
/*
* FUNCTION OPERATOR pg_dms_family_ref_pg_dms_family_ref_eq (a pg_dms_family_ref, b pg_dms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_family_ref_pg_dms_family_ref_eq (a pg_dms_family_ref, b pg_dms_family_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--1';
  RETURN a.family = b.family;
END;
$BODY$;
/*
* OPERATOR pg_dms_family_ref = pg_dms_family_ref
*/
CREATE OPERATOR pg_catalog. = (
PROCEDURE = pg_dms_family_ref_pg_dms_family_ref_eq, LEFTARG = pg_dms_family_ref, RIGHTARG = pg_dms_family_ref);
/*
* FUNCTION OPERATOR pg_dms_family_ref_pg_dms_family_ref_lt (a pg_dms_family_ref, b pg_dms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_family_ref_pg_dms_family_ref_lt (a pg_dms_family_ref, b pg_dms_family_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--2';
  RETURN a.family < b.family;
END;
$BODY$;
/*
* OPERATOR pg_dms_family_ref < pg_dms_family_ref
*/
CREATE OPERATOR pg_catalog. < (
PROCEDURE = pg_dms_family_ref_pg_dms_family_ref_lt, LEFTARG = pg_dms_family_ref, RIGHTARG = pg_dms_family_ref);
/*
* FUNCTION OPERATOR pg_dms_family_ref_pg_dms_family_ref_lt (a pg_dms_family_ref, b pg_dms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_family_ref_pg_dms_family_ref_le (a pg_dms_family_ref, b pg_dms_family_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--3';
  RETURN a.family <= b.family;
END;
$BODY$;
/*
* OPERATOR pg_dms_family_ref <= pg_dms_family_ref
*/
CREATE OPERATOR pg_catalog. <= (
PROCEDURE = pg_dms_family_ref_pg_dms_family_ref_le, LEFTARG = pg_dms_family_ref, RIGHTARG = pg_dms_family_ref);
/*
* FUNCTION OPERATOR pg_dms_family_ref_pg_dms_family_ref_lt (a pg_dms_family_ref, b pg_dms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_family_ref_pg_dms_family_ref_ge (a pg_dms_family_ref, b pg_dms_family_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--4';
  RETURN a.family >= b.family;
END;
$BODY$;
/*
* OPERATOR pg_dms_family_ref >= pg_dms_family_ref
*/
CREATE OPERATOR pg_catalog. >= (
PROCEDURE = pg_dms_family_ref_pg_dms_family_ref_ge, LEFTARG = pg_dms_family_ref, RIGHTARG = pg_dms_family_ref);
/*
* FUNCTION OPERATOR pg_dms_family_ref_pg_dms_family_ref_lt (a pg_dms_family_ref, b pg_dms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_family_ref_pg_dms_family_ref_gt (a pg_dms_family_ref, b pg_dms_family_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--5';
  RETURN a.family > b.family;
END;
$BODY$;
/*
* OPERATOR pg_dms_family_ref > pg_dms_family_ref
*/
CREATE OPERATOR pg_catalog. > (
PROCEDURE = pg_dms_family_ref_pg_dms_family_ref_gt, LEFTARG = pg_dms_family_ref, RIGHTARG = pg_dms_family_ref);
/*
* FUNCTION OPERATOR pg_dms_family_ref_pg_dms_family_ref_lt (a pg_dms_family_ref, b pg_dms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_family_ref_cmp (a pg_dms_family_ref, b pg_dms_family_ref)
  RETURNS integer
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--6';
  IF (a.family < b.family) THEN
    RETURN - 1;
  END IF;
  IF (a.family > b.family) THEN
    RETURN 1;
  END IF;
  IF (a.family = b.family) THEN
    RETURN 0;
  END IF;
END;
$BODY$;
/*
* OPERATOR class pg_dms_family_ref
*/
CREATE OPERATOR class pg_dms_family_ref DEFAULT FOR TYPE pg_dms_family_ref
USING btree family pg_dms_ops
AS OPERATOR 1 <,
OPERATOR 2 <=,
OPERATOR 3 =,
OPERATOR 4 >=,
OPERATOR 5 >,
FUNCTION 1 public.pg_dms_family_ref_cmp (pg_dms_family_ref,
  pg_dms_family_ref);
/*
* FUNCTION OPERATOR pg_dms_did_pg_dms_family_ref_eq (a pg_dms_family_ref, b pg_dms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_did_pg_dms_family_ref_eq (a pg_dms_did, b pg_dms_family_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--7';
  raise notice 'a.family % b.family %, a.id % a.status %', a.family, b.family, a.id, a.status;
  --IF (a.status = 'document'::pg_dms_status) THEN
    raise notice 'note--7 return %', a.family = b.family;
    RETURN a.family = b.family;
  --ELSE
  --  raise notice 'note--7 return --- false';
  --  RETURN FALSE;
  --END IF;
END;
$BODY$;
/*
* OPERATOR pg_dms_did = pg_dms_family_ref
*/
CREATE OPERATOR pg_catalog. = (
PROCEDURE = pg_dms_did_pg_dms_family_ref_eq, LEFTARG = pg_dms_did, RIGHTARG = pg_dms_family_ref);
/*
* FUNCTION OPERATOR pg_dms_did_pg_dms_family_ref_lt (a pg_dms_did, b pg_dms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_did_pg_dms_family_ref_lt (a pg_dms_did, b pg_dms_family_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--8';
  RETURN a.family < b.family
  AND a.status = 'document'::pg_dms_status;
END;
$BODY$;
/*
* OPERATOR pg_dms_did < pg_dms_family_ref
*/
CREATE OPERATOR pg_catalog. < (
PROCEDURE = pg_dms_did_pg_dms_family_ref_lt, LEFTARG = pg_dms_did, RIGHTARG = pg_dms_family_ref);
/*
* FUNCTION OPERATOR pg_dms_did_pg_dms_family_ref_lt (a pg_dms_did, b pg_dms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_did_pg_dms_family_ref_le (a pg_dms_did, b pg_dms_family_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--9';
  RETURN a.family <= b.family
  AND a.status = 'document'::pg_dms_status;
END;
$BODY$;
/*
* OPERATOR pg_dms_did <= pg_dms_family_ref
*/
CREATE OPERATOR pg_catalog. <= (
PROCEDURE = pg_dms_did_pg_dms_family_ref_le, LEFTARG = pg_dms_did, RIGHTARG = pg_dms_family_ref);
/*
* FUNCTION OPERATOR pg_dms_did_pg_dms_family_ref_lt (a pg_dms_did, b pg_dms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_did_pg_dms_family_ref_ge (a pg_dms_did, b pg_dms_family_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--10';
  RETURN a.family >= b.family
  AND a.status = 'document'::pg_dms_status;
END;
$BODY$;
/*
* OPERATOR pg_dms_did >= pg_dms_family_ref
*/
CREATE OPERATOR pg_catalog. >= (
PROCEDURE = pg_dms_did_pg_dms_family_ref_ge, LEFTARG = pg_dms_did, RIGHTARG = pg_dms_family_ref);
/*
* FUNCTION OPERATOR pg_dms_did_pg_dms_family_ref_lt (a pg_dms_did, b pg_dms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_did_pg_dms_family_ref_gt (a pg_dms_did, b pg_dms_family_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--11';
  RETURN a.family > b.family
  AND a.status = 'document'::pg_dms_status;
END;
$BODY$;
/*
* OPERATOR pg_dms_did > pg_dms_family_ref
*/
CREATE OPERATOR pg_catalog. > (
PROCEDURE = pg_dms_did_pg_dms_family_ref_gt, LEFTARG = pg_dms_did, RIGHTARG = pg_dms_family_ref);
/*
* FUNCTION OPERATOR pg_dms_did_pg_dms_family_ref_lt (a pg_dms_did, b pg_dms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_did_family_ref_cmp (a pg_dms_did, b pg_dms_family_ref)
  RETURNS integer
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--12';
  raise notice 'a.family % b.family %, a.id % a.status %', a.family, b.family, a.id, a.status;
  IF (a.family < b.family) THEN
    raise notice 'return -1';
    RETURN - 1;
  END IF;
  IF (a.family > b.family) THEN
    raise notice 'return 1';
    RETURN 1;
  END IF;
  IF (a.family = b.family) THEN
  --  IF (a.status = 'document'::pg_dms_status) THEN
      raise notice 'return-- 0';
      RETURN 0;
  --  ELSE
  --    raise notice 'return-- -1';
  --    RETURN - 1;
  --  END IF;
  END IF;
END;
$BODY$;
/*
* FUNCTION OPERATOR pg_dms_family_ref_pg_dms_did_eq (a pg_dms_family_ref, b pg_dms_did)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_family_ref_pg_dms_did_eq (a pg_dms_family_ref, b pg_dms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--13';
  RETURN a.family = b.family
  AND b.status = 'document'::pg_dms_status;
END;
$BODY$;
/*
* OPERATOR pg_dms_family_ref = pg_dms_did
*/
CREATE OPERATOR pg_catalog. = (
PROCEDURE = pg_dms_family_ref_pg_dms_did_eq, LEFTARG = pg_dms_family_ref, RIGHTARG = pg_dms_did);
/*
* FUNCTION OPERATOR pg_dms_family_ref_pg_dms_did_lt (a pg_dms_family_ref, b pg_dms_did)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_family_ref_pg_dms_did_lt (a pg_dms_family_ref, b pg_dms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--14';
  RETURN a.family < b.family
  AND b.status = 'document'::pg_dms_status;
END;
$BODY$;
/*
* OPERATOR pg_dms_family_ref < pg_dms_did
*/
CREATE OPERATOR pg_catalog. < (
PROCEDURE = pg_dms_family_ref_pg_dms_did_lt, LEFTARG = pg_dms_family_ref, RIGHTARG = pg_dms_did);
/*
* FUNCTION OPERATOR pg_dms_family_ref_pg_dms_did_lt (a pg_dms_family_ref, b pg_dms_did)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_family_ref_pg_dms_did_le (a pg_dms_family_ref, b pg_dms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--15';
  RETURN a.family <= b.family
  AND b.status = 'document'::pg_dms_status;
END;
$BODY$;
/*
* OPERATOR pg_dms_family_ref <= pg_dms_did
*/
CREATE OPERATOR pg_catalog. <= (
PROCEDURE = pg_dms_family_ref_pg_dms_did_le, LEFTARG = pg_dms_family_ref, RIGHTARG = pg_dms_did);
/*
* FUNCTION OPERATOR pg_dms_family_ref_pg_dms_did_lt (a pg_dms_family_ref, b pg_dms_did)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_family_ref_pg_dms_did_ge (a pg_dms_family_ref, b pg_dms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--16';
  RETURN a.family >= b.family
  AND b.status = 'document'::pg_dms_status;
END;
$BODY$;
/*
* OPERATOR pg_dms_family_ref >= pg_dms_did
*/
CREATE OPERATOR pg_catalog. >= (
PROCEDURE = pg_dms_family_ref_pg_dms_did_ge, LEFTARG = pg_dms_family_ref, RIGHTARG = pg_dms_did);
/*
* FUNCTION OPERATOR pg_dms_family_ref_pg_dms_did_lt (a pg_dms_family_ref, b pg_dms_did)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_family_ref_pg_dms_did_gt (a pg_dms_family_ref, b pg_dms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--17';
  RETURN a.family > b.family
  AND b.status = 'document'::pg_dms_status;
END;
$BODY$;
/*
* OPERATOR pg_dms_family_ref > pg_dms_did
*/
CREATE OPERATOR pg_catalog. > (
PROCEDURE = pg_dms_family_ref_pg_dms_did_gt, LEFTARG = pg_dms_family_ref, RIGHTARG = pg_dms_did);
/*
* FUNCTION OPERATOR pg_dms_family_ref_pg_dms_did_lt (a pg_dms_family_ref, b pg_dms_did)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_family_ref_did_cmp (a pg_dms_family_ref, b pg_dms_did)
  RETURNS integer
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--18';
  IF (b.status = 'document'::pg_dms_status) THEN
    IF (a.family < b.family) THEN
      RETURN - 1;
    END IF;
    IF (a.family > b.family) THEN
      RETURN 1;
    END IF;
    IF (a.family = b.family) THEN
      RETURN 0;
    END IF;
  ELSE
    RETURN - 1;
  END IF;
END;
$BODY$;
/*
-
-
* OPERATOR family pg_dms_ops 
-
-
*/
ALTER OPERATOR family pg_dms_ops
USING btree
  ADD -- cross-type comparisons pg_dms_did vs pg_dms_family_ref
  OPERATOR 1 < (pg_dms_did,
    pg_dms_family_ref),
  OPERATOR 2 <= (pg_dms_did,
    pg_dms_family_ref),
  OPERATOR 3 = (pg_dms_did,
    pg_dms_family_ref),
  OPERATOR 4 >= (pg_dms_did,
    pg_dms_family_ref),
  OPERATOR 5 > (pg_dms_did,
    pg_dms_family_ref),
  FUNCTION 1 public.pg_dms_did_family_ref_cmp (pg_dms_did,
    pg_dms_family_ref), -- cross-type comparisons pg_dms_family_ref vs pg_dms_did
  OPERATOR 1 < (pg_dms_family_ref,
    pg_dms_did),
  OPERATOR 2 <= (pg_dms_family_ref,
    pg_dms_did),
  OPERATOR 3 = (pg_dms_family_ref,
    pg_dms_did),
  OPERATOR 4 >= (pg_dms_family_ref,
    pg_dms_did),
  OPERATOR 5 > (pg_dms_family_ref,
    pg_dms_did),
  FUNCTION 1 public.pg_dms_family_ref_did_cmp (pg_dms_family_ref,
    pg_dms_did);
/*
-
-
-
* TYPE pg_dms_ref
-
-
-
*/
CREATE TYPE public.pg_dms_ref AS (
  family uuid,
  id uuid
);
COMMENT ON TYPE public.pg_dms_actiontype IS 'Тип поля зависимой таблицы котороый ссылается на таблицу с докуентами и не зависит от изменений документа';
/*
* FUNCTION OPERATOR pg_dms_ref_pg_dms_ref_eq (a pg_dms_ref, b pg_dms_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_ref_pg_dms_ref_eq (a pg_dms_ref, b pg_dms_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--200';
  RETURN a.family = b.family and a.id = b.id;
END;
$BODY$;
/*
* OPERATOR pg_dms_ref = pg_dms_ref
*/
CREATE OPERATOR pg_catalog. = (
PROCEDURE = pg_dms_ref_pg_dms_ref_eq, LEFTARG = pg_dms_ref, RIGHTARG = pg_dms_ref);
/*
* FUNCTION OPERATOR pg_dms_ref_pg_dms_ref_lt (a pg_dms_ref, b pg_dms_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_ref_pg_dms_ref_lt (a pg_dms_ref, b pg_dms_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--201';
  IF (a.family = b.family) THEN
    RETURN a.id < b.id;
  ELSE
    RETURN a.family < b.family;
  END IF;
END;
$BODY$;
/*
* OPERATOR pg_dms_ref < pg_dms_ref
*/
CREATE OPERATOR pg_catalog. < (
PROCEDURE = pg_dms_ref_pg_dms_ref_lt, LEFTARG = pg_dms_ref, RIGHTARG = pg_dms_ref);
/*
* FUNCTION OPERATOR pg_dms_ref_pg_dms_ref_lt (a pg_dms_ref, b pg_dms_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_ref_pg_dms_ref_le (a pg_dms_ref, b pg_dms_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--202';
  IF (a.family = b.family) THEN
    RETURN a.id <= b.id;
  ELSE
    RETURN a.family < b.family;
  END IF;
END;
$BODY$;
/*
* OPERATOR pg_dms_ref <= pg_dms_ref
*/
CREATE OPERATOR pg_catalog. <= (
PROCEDURE = pg_dms_ref_pg_dms_ref_le, LEFTARG = pg_dms_ref, RIGHTARG = pg_dms_ref);
/*
* FUNCTION OPERATOR pg_dms_ref_pg_dms_ref_lt (a pg_dms_ref, b pg_dms_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_ref_pg_dms_ref_ge (a pg_dms_ref, b pg_dms_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--203';
  IF (a.family = b.family) THEN
    RETURN a.id >= b.id;
  ELSE
    RETURN a.family > b.family;
  END IF;
END;
$BODY$;
/*
* OPERATOR pg_dms_ref >= pg_dms_ref
*/
CREATE OPERATOR pg_catalog. >= (
PROCEDURE = pg_dms_ref_pg_dms_ref_ge, LEFTARG = pg_dms_ref, RIGHTARG = pg_dms_ref);
/*
* FUNCTION OPERATOR pg_dms_ref_pg_dms_ref_lt (a pg_dms_ref, b pg_dms_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_ref_pg_dms_ref_gt (a pg_dms_ref, b pg_dms_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--204';
  IF (a.family = b.family) THEN
    RETURN a.id > b.id;
  ELSE
    RETURN a.family > b.family;
  END IF;
END;
$BODY$;
/*
* OPERATOR pg_dms_ref > pg_dms_ref
*/
CREATE OPERATOR pg_catalog. > (
PROCEDURE = pg_dms_ref_pg_dms_ref_gt, LEFTARG = pg_dms_ref, RIGHTARG = pg_dms_ref);
/*
* FUNCTION OPERATOR pg_dms_ref_pg_dms_ref_lt (a pg_dms_ref, b pg_dms_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_ref_cmp (a pg_dms_ref, b pg_dms_ref)
  RETURNS integer
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--205';
  IF (a.family = b.family) THEN
    IF (a.id < b.id) THEN
      RETURN - 1;
    END IF;
    IF (a.id > b.id) THEN
      RETURN 1;
    END IF;
    IF (a.id = b.id) THEN
      RETURN 0;
    END IF;
  ELSE
    IF (a.family < b.family) THEN
      RETURN - 1;
    END IF;
    IF (a.family > b.family) THEN
      RETURN 1;
    END IF;
  END IF;
END;
$BODY$;
/*
* OPERATOR class pg_dms_ref
*/
CREATE OPERATOR class pg_dms_ref DEFAULT FOR TYPE pg_dms_ref
USING btree family pg_dms_ops
AS OPERATOR 1 <,
OPERATOR 2 <=,
OPERATOR 3 =,
OPERATOR 4 >=,
OPERATOR 5 >,
FUNCTION 1 public.pg_dms_ref_cmp (pg_dms_ref,
  pg_dms_ref);
/*
* FUNCTION OPERATOR pg_dms_did_pg_dms_ref_eq (a pg_dms_ref, b pg_dms_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_did_pg_dms_ref_eq (a pg_dms_did, b pg_dms_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--206';
  RETURN a.family = b.family and a.id = b.id;
END;
$BODY$;
/*
* OPERATOR pg_dms_did = pg_dms_ref
*/
CREATE OPERATOR pg_catalog. = (
PROCEDURE = pg_dms_did_pg_dms_ref_eq, LEFTARG = pg_dms_did, RIGHTARG = pg_dms_ref);
/*
* FUNCTION OPERATOR pg_dms_did_pg_dms_ref_lt (a pg_dms_did, b pg_dms_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_did_pg_dms_ref_lt (a pg_dms_did, b pg_dms_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--207';
  IF (a.family = b.family) THEN
    RETURN a.id < b.id;
  ELSE
    RETURN a.family < b.family;
  END IF;
END;
$BODY$;
/*
* OPERATOR pg_dms_did < pg_dms_ref
*/
CREATE OPERATOR pg_catalog. < (
PROCEDURE = pg_dms_did_pg_dms_ref_lt, LEFTARG = pg_dms_did, RIGHTARG = pg_dms_ref);
/*
* FUNCTION OPERATOR pg_dms_did_pg_dms_ref_lt (a pg_dms_did, b pg_dms_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_did_pg_dms_ref_le (a pg_dms_did, b pg_dms_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--208';
  IF (a.family = b.family) THEN
    RETURN a.id <= b.id;
  ELSE
    RETURN a.family < b.family;
  END IF;
END;
$BODY$;
/*
* OPERATOR pg_dms_did <= pg_dms_ref
*/
CREATE OPERATOR pg_catalog. <= (
PROCEDURE = pg_dms_did_pg_dms_ref_le, LEFTARG = pg_dms_did, RIGHTARG = pg_dms_ref);
/*
* FUNCTION OPERATOR pg_dms_did_pg_dms_ref_lt (a pg_dms_did, b pg_dms_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_did_pg_dms_ref_ge (a pg_dms_did, b pg_dms_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--209';
  IF (a.family = b.family) THEN
    RETURN a.id >= b.id;
  ELSE
    RETURN a.family > b.family;
  END IF;
END;
$BODY$;
/*
* OPERATOR pg_dms_did >= pg_dms_ref
*/
CREATE OPERATOR pg_catalog. >= (
PROCEDURE = pg_dms_did_pg_dms_ref_ge, LEFTARG = pg_dms_did, RIGHTARG = pg_dms_ref);
/*
* FUNCTION OPERATOR pg_dms_did_pg_dms_ref_lt (a pg_dms_did, b pg_dms_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_did_pg_dms_ref_gt (a pg_dms_did, b pg_dms_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--210';
  IF (a.family = b.family) THEN
    RETURN a.id > b.id;
  ELSE
    RETURN a.family > b.family;
  END IF;
END;
$BODY$;
/*
* OPERATOR pg_dms_did > pg_dms_ref
*/
CREATE OPERATOR pg_catalog. > (
PROCEDURE = pg_dms_did_pg_dms_ref_gt, LEFTARG = pg_dms_did, RIGHTARG = pg_dms_ref);
/*
* FUNCTION OPERATOR pg_dms_did_pg_dms_ref_lt (a pg_dms_did, b pg_dms_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_did_ref_cmp (a pg_dms_did, b pg_dms_ref)
  RETURNS integer
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--211';
  raise notice 'a.family % b.family %, a.id % b.id %', a.family, b.family, a.id, b.id;

  IF (a.family = b.family) THEN
    IF (a.id < b.id) THEN
      raise notice 'note--211 -1';
      RETURN -1;
    END IF;
    IF (a.id > b.id) THEN
      raise notice 'note--211 1';
      RETURN 1;
    END IF;
    IF (a.id = b.id) THEN
      raise notice 'note--211 0';
      RETURN 0;
    END IF;
  ELSE
    IF (a.family < b.family) THEN
      raise notice 'note--211 -1';
      RETURN -1;
    END IF;
    IF (a.family > b.family) THEN
      raise notice 'note--211 1';
      RETURN 1;
    END IF;
  END IF;
END;
$BODY$;
/*
* FUNCTION OPERATOR pg_dms_ref_pg_dms_did_eq (a pg_dms_ref, b pg_dms_did)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_ref_pg_dms_did_eq (a pg_dms_ref, b pg_dms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--212';
  RETURN a.family = b.family and a.id = b.id;
END;
$BODY$;
/*
* OPERATOR pg_dms_ref = pg_dms_did
*/
CREATE OPERATOR pg_catalog. = (
PROCEDURE = pg_dms_ref_pg_dms_did_eq, LEFTARG = pg_dms_ref, RIGHTARG = pg_dms_did);
/*
* FUNCTION OPERATOR pg_dms_ref_pg_dms_did_lt (a pg_dms_ref, b pg_dms_did)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_ref_pg_dms_did_lt (a pg_dms_ref, b pg_dms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--213';
  IF (a.family = b.family) THEN
    RETURN a.id < b.id;
  ELSE
    RETURN a.family < b.family;
  END IF;
END;
$BODY$;
/*
* OPERATOR pg_dms_ref < pg_dms_did
*/
CREATE OPERATOR pg_catalog. < (
PROCEDURE = pg_dms_ref_pg_dms_did_lt, LEFTARG = pg_dms_ref, RIGHTARG = pg_dms_did);
/*
* FUNCTION OPERATOR pg_dms_ref_pg_dms_did_lt (a pg_dms_ref, b pg_dms_did)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_ref_pg_dms_did_le (a pg_dms_ref, b pg_dms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--214';
  IF (a.family = b.family) THEN
    RETURN a.id <= b.id;
  ELSE
    RETURN a.family < b.family;
  END IF;
END;
$BODY$;
/*
* OPERATOR pg_dms_ref <= pg_dms_did
*/
CREATE OPERATOR pg_catalog. <= (
PROCEDURE = pg_dms_ref_pg_dms_did_le, LEFTARG = pg_dms_ref, RIGHTARG = pg_dms_did);
/*
* FUNCTION OPERATOR pg_dms_ref_pg_dms_did_lt (a pg_dms_ref, b pg_dms_did)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_ref_pg_dms_did_ge (a pg_dms_ref, b pg_dms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--215';
  IF (a.family = b.family) THEN
    RETURN a.id >= b.id;
  ELSE
    RETURN a.family > b.family;
  END IF;
END;
$BODY$;
/*
* OPERATOR pg_dms_ref >= pg_dms_did
*/
CREATE OPERATOR pg_catalog. >= (
PROCEDURE = pg_dms_ref_pg_dms_did_ge, LEFTARG = pg_dms_ref, RIGHTARG = pg_dms_did);
/*
* FUNCTION OPERATOR pg_dms_ref_pg_dms_did_lt (a pg_dms_ref, b pg_dms_did)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_ref_pg_dms_did_gt (a pg_dms_ref, b pg_dms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--216';
  IF (a.family = b.family) THEN
    RETURN a.id > b.id;
  ELSE
    RETURN a.family > b.family;
  END IF;
END;
$BODY$;
/*
* OPERATOR pg_dms_ref > pg_dms_did
*/
CREATE OPERATOR pg_catalog. > (
PROCEDURE = pg_dms_ref_pg_dms_did_gt, LEFTARG = pg_dms_ref, RIGHTARG = pg_dms_did);
/*
* FUNCTION OPERATOR pg_dms_ref_pg_dms_did_lt (a pg_dms_ref, b pg_dms_did)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_ref_did_cmp (a pg_dms_ref, b pg_dms_did)
  RETURNS integer
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--217';
  IF (a.family = b.family) THEN
    IF (a.id < b.id) THEN
      RETURN - 1;
    END IF;
    IF (a.id > b.id) THEN
      RETURN 1;
    END IF;
    IF (a.id = b.id) THEN
      RETURN 0;
    END IF;
  ELSE
    IF (a.family < b.family) THEN
      RETURN - 1;
    END IF;
    IF (a.family > b.family) THEN
      RETURN 1;
    END IF;
  END IF;
END;
$BODY$;
/*
* OPERATOR family pg_dms_ops 
*/
ALTER OPERATOR family pg_dms_ops
USING btree
  ADD -- cross-type comparisons pg_dms_did vs pg_dms_ref
  OPERATOR 1 < (pg_dms_did,
    pg_dms_ref),
  OPERATOR 2 <= (pg_dms_did,
    pg_dms_ref),
  OPERATOR 3 = (pg_dms_did,
    pg_dms_ref),
  OPERATOR 4 >= (pg_dms_did,
    pg_dms_ref),
  OPERATOR 5 > (pg_dms_did,
    pg_dms_ref),
  FUNCTION 1 public.pg_dms_did_ref_cmp (pg_dms_did,
    pg_dms_ref), -- cross-type comparisons pg_dms_ref vs pg_dms_did
  OPERATOR 1 < (pg_dms_ref,
    pg_dms_did),
  OPERATOR 2 <= (pg_dms_ref,
    pg_dms_did),
  OPERATOR 3 = (pg_dms_ref,
    pg_dms_did),
  OPERATOR 4 >= (pg_dms_ref,
    pg_dms_did),
  OPERATOR 5 > (pg_dms_ref,
    pg_dms_did),
  FUNCTION 1 public.pg_dms_ref_did_cmp (pg_dms_ref,
    pg_dms_did);
/*
* FUNCTION OPERATOR pg_dms_didup_text_eq (a pg_dms_family_ref, b text)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_didup_text_eq (a pg_dms_family_ref, b text)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN a.family::text = substring(b, 1, 36);
END;
$BODY$;
/*
* OPERATOR pg_dms_family_ref = text
*/
CREATE OPERATOR pg_catalog. = (
PROCEDURE = pg_dms_didup_text_eq, LEFTARG = pg_dms_family_ref, RIGHTARG = text, COMMUTATOR = =, NEGATOR = <>, HASHES, MERGES);
/*
* FUNCTION OPERATOR pg_dms_did_uuid_eq (a pg_dms_did, b uuid)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_did_uuid_eq (a pg_dms_did, b uuid)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN a.id = b;
END;
$BODY$;
/*
* OPERATOR pg_dms_did = uuid
*/
CREATE OPERATOR pg_catalog. = (
PROCEDURE = pg_dms_did_uuid_eq, LEFTARG = pg_dms_did, RIGHTARG = uuid, COMMUTATOR = =, NEGATOR = <>, HASHES, MERGES);
/*
* FUNCTION OPERATOR pg_dms_didn_text_eq (a pg_dms_ref, b text)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_didn_text_eq (a pg_dms_ref, b text)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN a.family::text = substring(b, 1, 36) and a.id::text = substring(b, 38, 70);
END;
$BODY$;
/*
* OPERATOR pg_dms_ref = text
*/
CREATE OPERATOR pg_catalog. = (
PROCEDURE = pg_dms_didn_text_eq, LEFTARG = pg_dms_ref, RIGHTARG = text, COMMUTATOR = =, NEGATOR = <>, HASHES, MERGES);
/*
* FUNCTION OPERATOR pg_dms_did_pg_dms_status_eq (a pg_dms_did, b pg_dms_status)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_did_pg_dms_status_eq (a pg_dms_did, b pg_dms_status)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN a.status = b;
END;
$BODY$;
/*
* OPERATOR pg_dms_did = pg_dms_status
*/
CREATE OPERATOR pg_catalog. = (
PROCEDURE = pg_dms_did_pg_dms_status_eq, LEFTARG = pg_dms_did, RIGHTARG = pg_dms_status, COMMUTATOR = =, NEGATOR = <>, HASHES, MERGES);
/*
* FUNCTION CAST pg_dms_did (a uuid)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_did (a uuid)
  RETURNS pg_dms_did
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
DECLARE
  ret pg_dms_did;
BEGIN
  ret.id = uuid_generate_v4 ();
  ret.created = now();
  ret.ac [ 0 ] = (now(), (
      SELECT
        USER),
      'created'::pg_dms_actiontype,
      NULL)::pg_dms_action;
  IF (a IS NULL) THEN
    ret.family = ret.id;
  ELSE
    ret.family = a;
  END IF;
  ret.status = 'work'::pg_dms_status;
  RETURN ret;
END;
$BODY$;
/*
* CAST uuid => pg_dms_did
*/
CREATE CAST(
  uuid
AS pg_dms_did)
WITH FUNCTION public.pg_dms_did (uuid) AS
ASSIGNMENT;

/*
* FUNCTION CAST pg_dms_did (a text)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_did (a text)
  RETURNS pg_dms_did
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN public.pg_dms_did ((public.pg_dms_family_ref (a)).id);
END;
$BODY$;

/*
* CAST text => pg_dms_did
*/
CREATE CAST(
  text
AS pg_dms_did)
WITH FUNCTION public.pg_dms_did (text) AS ASSIGNMENT;
/*
* FUNCTION CAST pg_dms_family_ref (a uuid) 
*/
CREATE OR REPLACE FUNCTION public.pg_dms_family_ref (a uuid)
  RETURNS pg_dms_family_ref
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
DECLARE
  ret pg_dms_family_ref;
BEGIN
  ret.family = a;
  RETURN ret;
END;
$BODY$;
/*
* CAST uuid =>  pg_dms_family_ref
*/
CREATE CAST(
  uuid
AS pg_dms_family_ref)
WITH FUNCTION public.pg_dms_family_ref (uuid) AS
ASSIGNMENT;

/*
* FUNCTION CAST pg_dms_family_ref (a text)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_family_ref (a text)
  RETURNS pg_dms_family_ref
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
DECLARE
  ret pg_dms_family_ref;
BEGIN
  ret.family = substring(a, 1, 36)::uuid;
  RETURN ret;
END;
$BODY$;
/*
* FUNCTION OPERATOR pg_dms_did_text_eq (a pg_dms_did, b text)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_did_text_eq (a pg_dms_did, b text)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
DECLARE
  family text;
  id     text;
BEGIN
  family := substring(b, 1, 36);
  IF length(b) < 40 THEN
    IF (a.family = family::uuid) THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;
  ELSE
    id := substring(b, 38, 70);
    IF (a.family = family::uuid and a.id = id::uuid) THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;
  END IF;
END;
$BODY$;
/*
* OPERATOR pg_dms_did = text
*/
CREATE OPERATOR pg_catalog. = (
PROCEDURE = pg_dms_did_text_eq, LEFTARG = pg_dms_did, RIGHTARG = text, COMMUTATOR = =, NEGATOR = <>, HASHES, MERGES);
/*
* CAST text => pg_dms_family_ref  
*/
CREATE CAST(
  text
AS pg_dms_family_ref)
WITH FUNCTION public.pg_dms_family_ref (text) AS
ASSIGNMENT;

/*
* FUNCTION CAST pg_dms_ref (a text)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_ref (a text)
  RETURNS pg_dms_ref
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
DECLARE
  ret pg_dms_ref;
BEGIN
  ret.family = substring(a, 1, 36)::uuid;
  ret.id = substring(a, 38, 70)::uuid;
  RETURN ret;
END;
$BODY$;

/*
* CAST text => pg_dms_ref  
*/
CREATE CAST(
  text
AS pg_dms_ref)
WITH FUNCTION public.pg_dms_ref (text) AS ASSIGNMENT;
/*
* FUNCTION CAST pg_dms_uuid (a pg_dms_did)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_uuid (a pg_dms_did)
  RETURNS uuid
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN a.id;
END;
$BODY$;
/*
* CAST pg_dms_did => uuid  
*/
CREATE CAST(
  pg_dms_did
AS uuid)
WITH FUNCTION public.pg_dms_uuid (pg_dms_did) AS
ASSIGNMENT;

/*
* FUNCTION CAST pg_dms_uuid (a pg_dms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_uuid (a pg_dms_family_ref)
  RETURNS uuid
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN a.id;
END;
$BODY$;

/*
* CAST pg_dms_family_ref => uuid 
*/
CREATE CAST(
  pg_dms_family_ref
AS uuid)
WITH FUNCTION public.pg_dms_uuid (pg_dms_family_ref) AS ASSIGNMENT;
/*
* FUNCTION CAST pg_dms_text (a pg_dms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_text (a pg_dms_family_ref)
  RETURNS text
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN (a.id)::text;
END;
$BODY$;
/*
* CAST pg_dms_family_ref => text  
*/
CREATE CAST(
  pg_dms_family_ref
AS text)
WITH FUNCTION public.pg_dms_text (pg_dms_family_ref) AS
ASSIGNMENT;

/*
* FUNCTION CAST pg_dms_text (a pg_dms_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_text (a pg_dms_ref)
  RETURNS text
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN (a.family)::text || ',' || (a.id)::text;
END;
$BODY$;

/*
* CAST pg_dms_ref => text  
*/
CREATE CAST(
  pg_dms_ref
AS text)
WITH FUNCTION public.pg_dms_text (pg_dms_ref) AS ASSIGNMENT;
/*
* FUNCTION CAST pg_dms_text (a pg_dms_did)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_text (a pg_dms_did)
  RETURNS text
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN (a.family)::text || ',' || (a.id)::text;
END;
$BODY$;
/*
* CAST pg_dms_did => text 
*/
CREATE CAST(
  pg_dms_did
AS text)
WITH FUNCTION public.pg_dms_text (pg_dms_did) AS
ASSIGNMENT;

/*
* FUNCTION CAST pg_dms_uuid (a pg_dms_ref)
*/
CREATE OR REPLACE FUNCTION public.pg_dms_uuid (a pg_dms_ref)
  RETURNS uuid
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN a.id;
END;
$BODY$;

/*
* CAST pg_dms_ref => uuid 
*/
CREATE CAST(
  pg_dms_ref
AS uuid)
WITH FUNCTION public.pg_dms_uuid (pg_dms_ref) AS ASSIGNMENT;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pg_dms_setstatus_document (entity text, did pg_dms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  EXECUTE 'UPDATE ' || entity || '
                                    SET ' || pg_dms_get_pk (entity) || '.status = ''archival''::pg_dms_status, ' || pg_dms_get_pk (entity) || '.valid_until  = now()  
                                    WHERE (' || entity || '.' || pg_dms_get_pk (entity) || ').family = ''' || did.family || '''::uuid and (' || entity || '.' || pg_dms_get_pk (entity) || ').status = ''document''::pg_dms_status ';
  EXECUTE 'UPDATE ' || entity || '
                                    SET ' || pg_dms_get_pk (entity) || '.status = ''document''::pg_dms_status, ' || pg_dms_get_pk (entity) || '.valid_from   = now() 
                                    WHERE (' || entity || '.' || pg_dms_get_pk (entity) || ').id = ''' || did.id || '''::uuid';
  RETURN TRUE;
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pg_dms_set_hash (entity text, did pg_dms_did)
  RETURNS void
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
DECLARE
  o oid;
  h uuid;
BEGIN
  EXECUTE 'select tableoid from ' || entity || ' limit 1' INTO o;
  EXECUTE 'SELECT MD5(CONCAT(' || (
    SELECT
      string_agg(a.attname, ',')
    FROM
      pg_catalog.pg_attribute a
    WHERE
      a.attrelid = o
      AND a.attnum > 0
      AND a.attname <> pg_dms_get_pk (entity)) || '))::uuid from ' || entity || ' 
                                	WHERE (' || entity || '.' || pg_dms_get_pk (entity) || ').id = ''' || did.id || '''::uuid' INTO h;
  EXECUTE 'UPDATE ' || entity || '
                                   SET ' || pg_dms_get_pk (entity) || '.hash = ''' || h || '''
                                   WHERE (' || entity || '.' || pg_dms_get_pk (entity) || ').id = ''' || did.id || '''::uuid';
  RETURN;
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pg_dms_change_status (entity text, did pg_dms_did, status pg_dms_status)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  IF (did.status = 'work'::pg_dms_status) THEN
    IF (status = 'work'::pg_dms_status) THEN
      RETURN TRUE;
    END IF;
    IF (status = 'project'::pg_dms_status OR status = 'document'::pg_dms_status) THEN
      PERFORM
        pg_dms_set_hash (entity,
          did);
    END IF;
    IF (status = 'document'::pg_dms_status) THEN
      RETURN pg_dms_setstatus_document (entity,
        did);
    END IF;
  END IF;
  IF (did.status = 'project'::pg_dms_status) THEN
    IF (status = 'work'::pg_dms_status) THEN
      RETURN FALSE;
    END IF;
    IF (status = 'project'::pg_dms_status) THEN
      RETURN TRUE;
    END IF;
    IF (status = 'document'::pg_dms_status) THEN
      RETURN pg_dms_setstatus_document (entity,
        did);
    END IF;
  END IF;
  IF (did.status = 'document'::pg_dms_status) THEN
    IF (status = 'work'::pg_dms_status) THEN
      RETURN FALSE;
    END IF;
    IF (status = 'project'::pg_dms_status) THEN
      RETURN FALSE;
    END IF;
    IF (status = 'document'::pg_dms_status) THEN
      RETURN TRUE;
    END IF;
  END IF;
  EXECUTE 'UPDATE ' || entity || '
                                	SET ' || pg_dms_get_pk (entity) || '.status = ''' || status || ''' 
                                	WHERE (' || entity || '.' || pg_dms_get_pk (entity) || ').id = ''' || did.id || '''::uuid';
  RETURN TRUE;
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pg_dms_change_status (entity text, did pg_dms_did, status pg_dms_status)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  IF (did.status = 'work'::pg_dms_status) THEN
    IF (status = 'work'::pg_dms_status) THEN
      RETURN TRUE;
    END IF;
    IF (status = 'project'::pg_dms_status OR status = 'document'::pg_dms_status) THEN
      PERFORM
        pg_dms_set_hash (entity,
          did);
    END IF;
    IF (status = 'document'::pg_dms_status) THEN
      RETURN pg_dms_setstatus_document (entity,
        did);
    END IF;
  END IF;
  IF (did.status = 'project'::pg_dms_status) THEN
    IF (status = 'work'::pg_dms_status) THEN
      RETURN FALSE;
    END IF;
    IF (status = 'project'::pg_dms_status) THEN
      RETURN TRUE;
    END IF;
    IF (status = 'document'::pg_dms_status) THEN
      RETURN pg_dms_setstatus_document (entity,
        did);
    END IF;
  END IF;
  IF (did.status = 'document'::pg_dms_status) THEN
    IF (status = 'work'::pg_dms_status) THEN
      RETURN FALSE;
    END IF;
    IF (status = 'project'::pg_dms_status) THEN
      RETURN FALSE;
    END IF;
    IF (status = 'document'::pg_dms_status) THEN
      RETURN TRUE;
    END IF;
  END IF;
  EXECUTE 'UPDATE ' || entity || '
                                	SET ' || pg_dms_get_pk (entity) || '.status = ''' || status || ''' 
                                	WHERE (' || entity || '.' || pg_dms_get_pk (entity) || ').id = ''' || did.id || '''::uuid';
  RETURN TRUE;
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pg_dms_set_action (entity text, did pg_dms_did, action pg_dms_actiontype, note text)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
DECLARE
  f boolean;
BEGIN
  IF (action = 'created'::pg_dms_actiontype) THEN
    RAISE NOTICE 'Действие ''created'' создается автоматически';
    RETURN FALSE;
  END IF;
  EXECUTE 'UPDATE ' || entity || '
                                   SET ' || pg_dms_get_pk (entity) || '.ac = (' || entity || '.' || pg_dms_get_pk (entity) || ').ac || (''' || now() || ''',''' || (
    SELECT
      USER) || ''', ''' || action || '''::pg_dms_actiontype ,' || COALESCE('''' || note || '''', 'null') || ')::pg_dms_action
                                   WHERE (' || entity || '.' || pg_dms_get_pk (entity) || ').id = ''' || did.id || '''::uuid';
  IF (action = 'agreed'::pg_dms_actiontype) THEN
    IF (did.status = 'work'::pg_dms_status) THEN
      f = pg_dms_change_status (entity,
        did,
        'project'::pg_dms_status);
    END IF;
    RETURN TRUE;
  END IF;
  IF (action = 'approved'::pg_dms_actiontype) THEN
    IF (did.status = 'project'::pg_dms_status) THEN
      f = pg_dms_change_status (entity,
        did,
        'document'::pg_dms_status);
    END IF;
    RETURN TRUE;
  END IF;
  RETURN TRUE;
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pg_dms_get_did (entity text, k text)
  RETURNS pg_dms_did
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
DECLARE
  did pg_dms_did;
BEGIN
  EXECUTE 'SELECT (' || pg_dms_get_pk (entity) || ').id FROM ' || entity || ' WHERE (' || entity || '.' || pg_dms_get_pk (entity) || ').id = ''' || substring(k, 1, 36) || '''::uuid' INTO did.id;
  EXECUTE 'SELECT (' || pg_dms_get_pk (entity) || ').family FROM ' || entity || ' WHERE (' || entity || '.' || pg_dms_get_pk (entity) || ').id = ''' || substring(k, 1, 36) || '''::uuid' INTO did.family;
  EXECUTE 'SELECT (' || pg_dms_get_pk (entity) || ').status FROM ' || entity || ' WHERE (' || entity || '.' || pg_dms_get_pk (entity) || ').id = ''' || substring(k, 1, 36) || '''::uuid' INTO did.status;
  EXECUTE 'SELECT (' || pg_dms_get_pk (entity) || ').created FROM ' || entity || ' WHERE (' || entity || '.' || pg_dms_get_pk (entity) || ').id = ''' || substring(k, 1, 36) || '''::uuid' INTO did.created;
  EXECUTE 'SELECT (' || pg_dms_get_pk (entity) || ').hash FROM ' || entity || ' WHERE (' || entity || '.' || pg_dms_get_pk (entity) || ').id = ''' || substring(k, 1, 36) || '''::uuid' INTO did.hash;
  EXECUTE 'SELECT (' || pg_dms_get_pk (entity) || ').valid_from FROM ' || entity || ' WHERE (' || entity || '.' || pg_dms_get_pk (entity) || ').id = ''' || substring(k, 1, 36) || '''::uuid' INTO did.valid_from;
  EXECUTE 'SELECT (' || pg_dms_get_pk (entity) || ').valid_until FROM ' || entity || ' WHERE (' || entity || '.' || pg_dms_get_pk (entity) || ').id = ''' || substring(k, 1, 36) || '''::uuid' INTO did.valid_until;
  EXECUTE 'SELECT (' || pg_dms_get_pk (entity) || ').ac FROM ' || entity || ' WHERE (' || entity || '.' || pg_dms_get_pk (entity) || ').id = ''' || substring(k, 1, 36) || '''::uuid' INTO did.ac;
  RETURN did;
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pg_dms_set_action (entity text, k text, action pg_dms_actiontype, note text)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN public.pg_dms_set_action (entity,
    pg_dms_get_did (entity,
      k),
    action,
    note);
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pg_dms_get_actions (a pg_dms_did)
  RETURNS text
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN pg_dms_to_text ((a).ac);
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pg_dms_get_status (a pg_dms_did)
  RETURNS text
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN pg_dms_to_text ((a).status);
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pg_dms_get_hash (a pg_dms_did)
  RETURNS text
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN (a).hash;
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pg_dms_is_document (a pg_dms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN (a).status = 'document'::pg_dms_status;
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pg_dms_is_document (a pg_dms_did, ts timestamp WITH time zone)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN (((a).status = 'document'::pg_dms_status
      OR (a).status = 'archival'::pg_dms_status)
    AND (a).valid_from <= ts
    AND ((a).valid_until > ts
      OR (a).valid_until IS NULL));
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pg_dms_is_family (a pg_dms_did, f pg_dms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN (a).family = f.family;
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pg_dms_is_family (a pg_dms_did, f text)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN (a).family = substring(f, 1, 36)::uuid;
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pg_dms_is_last (entity text, a pg_dms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
DECLARE
  f uuid;
BEGIN
  EXECUTE 'SELECT (' || entity || '.' || pg_dms_get_pk (entity) || ').id 
                            from ' || entity || ' where (' || entity || '.' || pg_dms_get_pk (entity) || ').family = ''' || (a).family || ''' order by (' || entity || '.' || pg_dms_get_pk (entity) || ').family desc limit 1' INTO f;
  IF ((a).id = f) THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$BODY$;
