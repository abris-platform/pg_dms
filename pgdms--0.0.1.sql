-- complain IF script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pgdms" to load this file. \quit



CREATE FUNCTION pgdms_d_in(cstring)
    RETURNS pgdms_d
    AS 'pgdms.so'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION pgdms_d_out(pgdms_d)
    RETURNS cstring
    AS 'pgdms.so'
    LANGUAGE C IMMUTABLE STRICT;



CREATE TYPE pgdms_d (
   internallength = VARIABLE,
   input = pgdms_d_in,
   output = pgdms_d_out,
--   receive = pgdms_d_recv,
--   send = pgdms_d_send,
   alignment = double
);


/*
* FUNCTION pgdms_get_pk (entity text)
*/
CREATE FUNCTION public.pgdms_get_pk (entity text)
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

COMMENT ON FUNCTION public.pgdms_get_pk (entity text)
IS 'Возвращает назване колонки содержащие первичный ключ.
                      entity - сущьность для которой ищется первичный ключ.';

/*
* TYPE pgdms_actiontype
*/
CREATE TYPE public.pgdms_actiontype AS ENUM ( 'created',
  'agreed',
  'approved',
  'rejected'
);

COMMENT ON TYPE public.pgdms_actiontype IS 'Действия которые можно совершать с документами (строкой)';

/*
* FUNCTION public.pgdms_to_text (a pgdms_actiontype)
*/
CREATE OR REPLACE FUNCTION public.pgdms_to_text (a pgdms_actiontype)
  RETURNS text
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  IF (a = 'created'::pgdms_actiontype) THEN
    RETURN 'Создано';
  END IF;
  IF (a = 'agreed'::pgdms_actiontype) THEN
    RETURN 'Согласовано';
  END IF;
  IF (a = 'approved'::pgdms_actiontype) THEN
    RETURN 'Утверждено';
  END IF;
  IF (a = 'rejected'::pgdms_actiontype) THEN
    RETURN 'Отклонено';
  END IF;
END;
$BODY$;

/*
* TYPE pgdms_action
*/
CREATE TYPE public.pgdms_action AS (
  created timestamp WITH time zone,
  usr text,
  act pgdms_actiontype,
  note text
);

COMMENT ON TYPE public.pgdms_actiontype IS 'Действиe которые совершено с документом (строкой)';

/*
* TYPE pgdms_status
*/
CREATE TYPE public.pgdms_status AS ENUM ( 'work',
  'project',
  'document',
  'archival'
);

COMMENT ON TYPE public.pgdms_actiontype IS 'Состояние документа (строки)';

/*
* FUNCTION pgdms_to_text (a pgdms_status)
*/
CREATE OR REPLACE FUNCTION public.pgdms_to_text (a pgdms_status)
  RETURNS text
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  IF (a = 'work'::pgdms_status) THEN
    RETURN 'Материал';
  END IF;
  IF (a = 'project'::pgdms_status) THEN
    RETURN 'Проект';
  END IF;
  IF (a = 'document'::pgdms_status) THEN
    RETURN 'Документ';
  END IF;
  IF (a = 'archival'::pgdms_status) THEN
    RETURN 'Архив';
  END IF;
END;
$BODY$;

/*
* FUNCTION pgdms_to_text (a timestamp WITH time zone)
*/
CREATE OR REPLACE FUNCTION public.pgdms_to_text (a timestamp WITH time zone)
  RETURNS text
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN to_char(a, 'DD.MM.YY HH24:MI');
END;
$BODY$;

/*
* FUNCTION CAST pgdms_to_text (a pgdms_action)
*/
CREATE OR REPLACE FUNCTION public.pgdms_to_text (a pgdms_action)
  RETURNS text
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN pgdms_to_text ((a).created) || ' ' || pgdms_to_text ((a).act) || ' ' || (a).usr || COALESCE(' (' || (a).note || ')',
    '');
END;
$BODY$;

/*
* CAST pgdms_action => text
*/
CREATE CAST(
  pgdms_action
AS text)
WITH FUNCTION public.pgdms_to_text (pgdms_action) AS ASSIGNMENT;
/*
* FUNCTION pgdms_to_text (a pgdms_action)
*/
CREATE OR REPLACE FUNCTION public.pgdms_to_text (a pgdms_action [ ])
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
* OPERATOR family pgdms_ops
*/
CREATE OPERATOR family pgdms_ops
USING btree;
/*
-
-
-
* TYPE pgdms_did
-
-
-
*/
CREATE TYPE public.pgdms_did AS (
  family uuid,
  id uuid,
  status pgdms_status,
  created timestamp WITH time zone,
  hash uuid,
  valid_from timestamp WITH time zone,
  valid_until timestamp WITH time zone,
  ac pgdms_action [ ]
);
COMMENT ON TYPE public.pgdms_actiontype IS 'Тип ключевого поля для документа (строки) в котором храниться вся информация и состоянии и действиях со строкой';
/*
* FUNCTION OPERATOR pgdms_did_pgdms_did_eq (a pgdms_did, b pgdms_did)
*/
CREATE OR REPLACE FUNCTION public.pgdms_did_pgdms_did_eq (a pgdms_did, b pgdms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--100';
  RETURN a.id = b.id;
END;
$BODY$;
/*
* OPERATOR pgdms_did = pgdms_did
*/
CREATE OPERATOR pg_catalog. #=# (
PROCEDURE = pgdms_did_pgdms_did_eq, LEFTARG = pgdms_did, RIGHTARG = pgdms_did);
/*
* FUNCTION OPERATOR pgdms_did_pgdms_did_lt (a pgdms_did, b pgdms_did)
*/
CREATE OR REPLACE FUNCTION public.pgdms_did_pgdms_did_lt (a pgdms_did, b pgdms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--101';
  RETURN a.id < b.id;
END;
$BODY$;
/*
* OPERATOR pgdms_did < pgdms_did
*/
CREATE OPERATOR pg_catalog. #<# (
PROCEDURE = pgdms_did_pgdms_did_lt, LEFTARG = pgdms_did, RIGHTARG = pgdms_did);
/*
* FUNCTION OPERATOR pgdms_did_pgdms_did_lt (a pgdms_did, b pgdms_did)
*/
CREATE OR REPLACE FUNCTION public.pgdms_did_pgdms_did_le (a pgdms_did, b pgdms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--102';
  RETURN a.id <= b.id;
END;
$BODY$;
/*
* OPERATOR pgdms_did <= pgdms_did
*/
CREATE OPERATOR pg_catalog. #<=# (
PROCEDURE = pgdms_did_pgdms_did_le, LEFTARG = pgdms_did, RIGHTARG = pgdms_did);
/*
* FUNCTION OPERATOR pgdms_did_pgdms_did_lt (a pgdms_did, b pgdms_did)
*/
CREATE OR REPLACE FUNCTION public.pgdms_did_pgdms_did_ge (a pgdms_did, b pgdms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--103';
  RETURN a.id >= b.id;
END;
$BODY$;
/*
* OPERATOR pgdms_did >= pgdms_did
*/
CREATE OPERATOR pg_catalog. #>=# (
PROCEDURE = pgdms_did_pgdms_did_ge, LEFTARG = pgdms_did, RIGHTARG = pgdms_did);
/*
* FUNCTION OPERATOR pgdms_did_pgdms_did_lt (a pgdms_did, b pgdms_did)
*/
CREATE OR REPLACE FUNCTION public.pgdms_did_pgdms_did_gt (a pgdms_did, b pgdms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--104';
  RETURN a.id > b.id;
END;
$BODY$;
/*
* OPERATOR pgdms_did > pgdms_did
*/
CREATE OPERATOR pg_catalog. #># (
PROCEDURE = pgdms_did_pgdms_did_gt, LEFTARG = pgdms_did, RIGHTARG = pgdms_did);
/*
* FUNCTION OPERATOR pgdms_did_pgdms_did_lt (a pgdms_did, b pgdms_did)
*/
CREATE OR REPLACE FUNCTION public.pgdms_did_cmp (a pgdms_did, b pgdms_did)
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
* OPERATOR class pgdms_did
*/
CREATE OPERATOR class pgdms_did DEFAULT FOR TYPE pgdms_did
USING btree family pgdms_ops
AS OPERATOR 1 #<#,
OPERATOR 2 #<=#,
OPERATOR 3 #=#,
OPERATOR 4 #>=#,
OPERATOR 5 #>#,
FUNCTION 1 public.pgdms_did_cmp (pgdms_did,
  pgdms_did);
/*
-
-
* TYPE pgdms_family_ref
-
-
*/
CREATE TYPE public.pgdms_family_ref AS (
  family uuid
);
COMMENT ON TYPE public.pgdms_actiontype IS 'Тип поля зависимой таблицы котороый ссылается на таблицу с докуентами и зависит от изменений документа';
/*
* FUNCTION OPERATOR pgdms_family_ref_pgdms_family_ref_eq (a pgdms_family_ref, b pgdms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_family_ref_pgdms_family_ref_eq (a pgdms_family_ref, b pgdms_family_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--1';
  RETURN a.family = b.family;
END;
$BODY$;
/*
* OPERATOR pgdms_family_ref = pgdms_family_ref
*/
CREATE OPERATOR pg_catalog. = (
PROCEDURE = pgdms_family_ref_pgdms_family_ref_eq, LEFTARG = pgdms_family_ref, RIGHTARG = pgdms_family_ref);
/*
* FUNCTION OPERATOR pgdms_family_ref_pgdms_family_ref_lt (a pgdms_family_ref, b pgdms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_family_ref_pgdms_family_ref_lt (a pgdms_family_ref, b pgdms_family_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--2';
  RETURN a.family < b.family;
END;
$BODY$;
/*
* OPERATOR pgdms_family_ref < pgdms_family_ref
*/
CREATE OPERATOR pg_catalog. < (
PROCEDURE = pgdms_family_ref_pgdms_family_ref_lt, LEFTARG = pgdms_family_ref, RIGHTARG = pgdms_family_ref);
/*
* FUNCTION OPERATOR pgdms_family_ref_pgdms_family_ref_lt (a pgdms_family_ref, b pgdms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_family_ref_pgdms_family_ref_le (a pgdms_family_ref, b pgdms_family_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--3';
  RETURN a.family <= b.family;
END;
$BODY$;
/*
* OPERATOR pgdms_family_ref <= pgdms_family_ref
*/
CREATE OPERATOR pg_catalog. <= (
PROCEDURE = pgdms_family_ref_pgdms_family_ref_le, LEFTARG = pgdms_family_ref, RIGHTARG = pgdms_family_ref);
/*
* FUNCTION OPERATOR pgdms_family_ref_pgdms_family_ref_lt (a pgdms_family_ref, b pgdms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_family_ref_pgdms_family_ref_ge (a pgdms_family_ref, b pgdms_family_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--4';
  RETURN a.family >= b.family;
END;
$BODY$;
/*
* OPERATOR pgdms_family_ref >= pgdms_family_ref
*/
CREATE OPERATOR pg_catalog. >= (
PROCEDURE = pgdms_family_ref_pgdms_family_ref_ge, LEFTARG = pgdms_family_ref, RIGHTARG = pgdms_family_ref);
/*
* FUNCTION OPERATOR pgdms_family_ref_pgdms_family_ref_lt (a pgdms_family_ref, b pgdms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_family_ref_pgdms_family_ref_gt (a pgdms_family_ref, b pgdms_family_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--5';
  RETURN a.family > b.family;
END;
$BODY$;
/*
* OPERATOR pgdms_family_ref > pgdms_family_ref
*/
CREATE OPERATOR pg_catalog. > (
PROCEDURE = pgdms_family_ref_pgdms_family_ref_gt, LEFTARG = pgdms_family_ref, RIGHTARG = pgdms_family_ref);
/*
* FUNCTION OPERATOR pgdms_family_ref_pgdms_family_ref_lt (a pgdms_family_ref, b pgdms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_family_ref_cmp (a pgdms_family_ref, b pgdms_family_ref)
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
* OPERATOR class pgdms_family_ref
*/
CREATE OPERATOR class pgdms_family_ref DEFAULT FOR TYPE pgdms_family_ref
USING btree family pgdms_ops
AS OPERATOR 1 <,
OPERATOR 2 <=,
OPERATOR 3 =,
OPERATOR 4 >=,
OPERATOR 5 >,
FUNCTION 1 public.pgdms_family_ref_cmp (pgdms_family_ref,
  pgdms_family_ref);
/*
* FUNCTION OPERATOR pgdms_did_pgdms_family_ref_eq (a pgdms_family_ref, b pgdms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_did_pgdms_family_ref_eq (a pgdms_did, b pgdms_family_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--7';
  raise notice 'a.family % b.family %, a.id % a.status %', a.family, b.family, a.id, a.status;
  --IF (a.status = 'document'::pgdms_status) THEN
    raise notice 'note--7 return %', a.family = b.family;
    RETURN a.family = b.family;
  --ELSE
  --  raise notice 'note--7 return --- false';
  --  RETURN FALSE;
  --END IF;
END;
$BODY$;
/*
* OPERATOR pgdms_did = pgdms_family_ref
*/
CREATE OPERATOR pg_catalog. = (
PROCEDURE = pgdms_did_pgdms_family_ref_eq, LEFTARG = pgdms_did, RIGHTARG = pgdms_family_ref);
/*
* FUNCTION OPERATOR pgdms_did_pgdms_family_ref_lt (a pgdms_did, b pgdms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_did_pgdms_family_ref_lt (a pgdms_did, b pgdms_family_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--8';
  RETURN a.family < b.family
  AND a.status = 'document'::pgdms_status;
END;
$BODY$;
/*
* OPERATOR pgdms_did < pgdms_family_ref
*/
CREATE OPERATOR pg_catalog. < (
PROCEDURE = pgdms_did_pgdms_family_ref_lt, LEFTARG = pgdms_did, RIGHTARG = pgdms_family_ref);
/*
* FUNCTION OPERATOR pgdms_did_pgdms_family_ref_lt (a pgdms_did, b pgdms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_did_pgdms_family_ref_le (a pgdms_did, b pgdms_family_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--9';
  RETURN a.family <= b.family
  AND a.status = 'document'::pgdms_status;
END;
$BODY$;
/*
* OPERATOR pgdms_did <= pgdms_family_ref
*/
CREATE OPERATOR pg_catalog. <= (
PROCEDURE = pgdms_did_pgdms_family_ref_le, LEFTARG = pgdms_did, RIGHTARG = pgdms_family_ref);
/*
* FUNCTION OPERATOR pgdms_did_pgdms_family_ref_lt (a pgdms_did, b pgdms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_did_pgdms_family_ref_ge (a pgdms_did, b pgdms_family_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--10';
  RETURN a.family >= b.family
  AND a.status = 'document'::pgdms_status;
END;
$BODY$;
/*
* OPERATOR pgdms_did >= pgdms_family_ref
*/
CREATE OPERATOR pg_catalog. >= (
PROCEDURE = pgdms_did_pgdms_family_ref_ge, LEFTARG = pgdms_did, RIGHTARG = pgdms_family_ref);
/*
* FUNCTION OPERATOR pgdms_did_pgdms_family_ref_lt (a pgdms_did, b pgdms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_did_pgdms_family_ref_gt (a pgdms_did, b pgdms_family_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--11';
  RETURN a.family > b.family
  AND a.status = 'document'::pgdms_status;
END;
$BODY$;
/*
* OPERATOR pgdms_did > pgdms_family_ref
*/
CREATE OPERATOR pg_catalog. > (
PROCEDURE = pgdms_did_pgdms_family_ref_gt, LEFTARG = pgdms_did, RIGHTARG = pgdms_family_ref);
/*
* FUNCTION OPERATOR pgdms_did_pgdms_family_ref_lt (a pgdms_did, b pgdms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_did_family_ref_cmp (a pgdms_did, b pgdms_family_ref)
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
  --  IF (a.status = 'document'::pgdms_status) THEN
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
* FUNCTION OPERATOR pgdms_family_ref_pgdms_did_eq (a pgdms_family_ref, b pgdms_did)
*/
CREATE OR REPLACE FUNCTION public.pgdms_family_ref_pgdms_did_eq (a pgdms_family_ref, b pgdms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--13';
  RETURN a.family = b.family
  AND b.status = 'document'::pgdms_status;
END;
$BODY$;
/*
* OPERATOR pgdms_family_ref = pgdms_did
*/
CREATE OPERATOR pg_catalog. = (
PROCEDURE = pgdms_family_ref_pgdms_did_eq, LEFTARG = pgdms_family_ref, RIGHTARG = pgdms_did);
/*
* FUNCTION OPERATOR pgdms_family_ref_pgdms_did_lt (a pgdms_family_ref, b pgdms_did)
*/
CREATE OR REPLACE FUNCTION public.pgdms_family_ref_pgdms_did_lt (a pgdms_family_ref, b pgdms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--14';
  RETURN a.family < b.family
  AND b.status = 'document'::pgdms_status;
END;
$BODY$;
/*
* OPERATOR pgdms_family_ref < pgdms_did
*/
CREATE OPERATOR pg_catalog. < (
PROCEDURE = pgdms_family_ref_pgdms_did_lt, LEFTARG = pgdms_family_ref, RIGHTARG = pgdms_did);
/*
* FUNCTION OPERATOR pgdms_family_ref_pgdms_did_lt (a pgdms_family_ref, b pgdms_did)
*/
CREATE OR REPLACE FUNCTION public.pgdms_family_ref_pgdms_did_le (a pgdms_family_ref, b pgdms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--15';
  RETURN a.family <= b.family
  AND b.status = 'document'::pgdms_status;
END;
$BODY$;
/*
* OPERATOR pgdms_family_ref <= pgdms_did
*/
CREATE OPERATOR pg_catalog. <= (
PROCEDURE = pgdms_family_ref_pgdms_did_le, LEFTARG = pgdms_family_ref, RIGHTARG = pgdms_did);
/*
* FUNCTION OPERATOR pgdms_family_ref_pgdms_did_lt (a pgdms_family_ref, b pgdms_did)
*/
CREATE OR REPLACE FUNCTION public.pgdms_family_ref_pgdms_did_ge (a pgdms_family_ref, b pgdms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--16';
  RETURN a.family >= b.family
  AND b.status = 'document'::pgdms_status;
END;
$BODY$;
/*
* OPERATOR pgdms_family_ref >= pgdms_did
*/
CREATE OPERATOR pg_catalog. >= (
PROCEDURE = pgdms_family_ref_pgdms_did_ge, LEFTARG = pgdms_family_ref, RIGHTARG = pgdms_did);
/*
* FUNCTION OPERATOR pgdms_family_ref_pgdms_did_lt (a pgdms_family_ref, b pgdms_did)
*/
CREATE OR REPLACE FUNCTION public.pgdms_family_ref_pgdms_did_gt (a pgdms_family_ref, b pgdms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--17';
  RETURN a.family > b.family
  AND b.status = 'document'::pgdms_status;
END;
$BODY$;
/*
* OPERATOR pgdms_family_ref > pgdms_did
*/
CREATE OPERATOR pg_catalog. > (
PROCEDURE = pgdms_family_ref_pgdms_did_gt, LEFTARG = pgdms_family_ref, RIGHTARG = pgdms_did);
/*
* FUNCTION OPERATOR pgdms_family_ref_pgdms_did_lt (a pgdms_family_ref, b pgdms_did)
*/
CREATE OR REPLACE FUNCTION public.pgdms_family_ref_did_cmp (a pgdms_family_ref, b pgdms_did)
  RETURNS integer
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--18';
  IF (b.status = 'document'::pgdms_status) THEN
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
* OPERATOR family pgdms_ops 
-
-
*/
ALTER OPERATOR family pgdms_ops
USING btree
  ADD -- cross-type comparisons pgdms_did vs pgdms_family_ref
  OPERATOR 1 < (pgdms_did,
    pgdms_family_ref),
  OPERATOR 2 <= (pgdms_did,
    pgdms_family_ref),
  OPERATOR 3 = (pgdms_did,
    pgdms_family_ref),
  OPERATOR 4 >= (pgdms_did,
    pgdms_family_ref),
  OPERATOR 5 > (pgdms_did,
    pgdms_family_ref),
  FUNCTION 1 public.pgdms_did_family_ref_cmp (pgdms_did,
    pgdms_family_ref), -- cross-type comparisons pgdms_family_ref vs pgdms_did
  OPERATOR 1 < (pgdms_family_ref,
    pgdms_did),
  OPERATOR 2 <= (pgdms_family_ref,
    pgdms_did),
  OPERATOR 3 = (pgdms_family_ref,
    pgdms_did),
  OPERATOR 4 >= (pgdms_family_ref,
    pgdms_did),
  OPERATOR 5 > (pgdms_family_ref,
    pgdms_did),
  FUNCTION 1 public.pgdms_family_ref_did_cmp (pgdms_family_ref,
    pgdms_did);
/*
-
-
-
* TYPE pgdms_ref
-
-
-
*/
CREATE TYPE public.pgdms_ref AS (
  family uuid,
  id uuid
);
COMMENT ON TYPE public.pgdms_actiontype IS 'Тип поля зависимой таблицы котороый ссылается на таблицу с докуентами и не зависит от изменений документа';
/*
* FUNCTION OPERATOR pgdms_ref_pgdms_ref_eq (a pgdms_ref, b pgdms_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_ref_pgdms_ref_eq (a pgdms_ref, b pgdms_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--200';
  RETURN a.family = b.family and a.id = b.id;
END;
$BODY$;
/*
* OPERATOR pgdms_ref = pgdms_ref
*/
CREATE OPERATOR pg_catalog. = (
PROCEDURE = pgdms_ref_pgdms_ref_eq, LEFTARG = pgdms_ref, RIGHTARG = pgdms_ref);
/*
* FUNCTION OPERATOR pgdms_ref_pgdms_ref_lt (a pgdms_ref, b pgdms_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_ref_pgdms_ref_lt (a pgdms_ref, b pgdms_ref)
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
* OPERATOR pgdms_ref < pgdms_ref
*/
CREATE OPERATOR pg_catalog. < (
PROCEDURE = pgdms_ref_pgdms_ref_lt, LEFTARG = pgdms_ref, RIGHTARG = pgdms_ref);
/*
* FUNCTION OPERATOR pgdms_ref_pgdms_ref_lt (a pgdms_ref, b pgdms_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_ref_pgdms_ref_le (a pgdms_ref, b pgdms_ref)
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
* OPERATOR pgdms_ref <= pgdms_ref
*/
CREATE OPERATOR pg_catalog. <= (
PROCEDURE = pgdms_ref_pgdms_ref_le, LEFTARG = pgdms_ref, RIGHTARG = pgdms_ref);
/*
* FUNCTION OPERATOR pgdms_ref_pgdms_ref_lt (a pgdms_ref, b pgdms_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_ref_pgdms_ref_ge (a pgdms_ref, b pgdms_ref)
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
* OPERATOR pgdms_ref >= pgdms_ref
*/
CREATE OPERATOR pg_catalog. >= (
PROCEDURE = pgdms_ref_pgdms_ref_ge, LEFTARG = pgdms_ref, RIGHTARG = pgdms_ref);
/*
* FUNCTION OPERATOR pgdms_ref_pgdms_ref_lt (a pgdms_ref, b pgdms_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_ref_pgdms_ref_gt (a pgdms_ref, b pgdms_ref)
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
* OPERATOR pgdms_ref > pgdms_ref
*/
CREATE OPERATOR pg_catalog. > (
PROCEDURE = pgdms_ref_pgdms_ref_gt, LEFTARG = pgdms_ref, RIGHTARG = pgdms_ref);
/*
* FUNCTION OPERATOR pgdms_ref_pgdms_ref_lt (a pgdms_ref, b pgdms_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_ref_cmp (a pgdms_ref, b pgdms_ref)
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
* OPERATOR class pgdms_ref
*/
CREATE OPERATOR class pgdms_ref DEFAULT FOR TYPE pgdms_ref
USING btree family pgdms_ops
AS OPERATOR 1 <,
OPERATOR 2 <=,
OPERATOR 3 =,
OPERATOR 4 >=,
OPERATOR 5 >,
FUNCTION 1 public.pgdms_ref_cmp (pgdms_ref,
  pgdms_ref);
/*
* FUNCTION OPERATOR pgdms_did_pgdms_ref_eq (a pgdms_ref, b pgdms_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_did_pgdms_ref_eq (a pgdms_did, b pgdms_ref)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--206';
  RETURN a.family = b.family and a.id = b.id;
END;
$BODY$;
/*
* OPERATOR pgdms_did = pgdms_ref
*/
CREATE OPERATOR pg_catalog. = (
PROCEDURE = pgdms_did_pgdms_ref_eq, LEFTARG = pgdms_did, RIGHTARG = pgdms_ref);
/*
* FUNCTION OPERATOR pgdms_did_pgdms_ref_lt (a pgdms_did, b pgdms_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_did_pgdms_ref_lt (a pgdms_did, b pgdms_ref)
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
* OPERATOR pgdms_did < pgdms_ref
*/
CREATE OPERATOR pg_catalog. < (
PROCEDURE = pgdms_did_pgdms_ref_lt, LEFTARG = pgdms_did, RIGHTARG = pgdms_ref);
/*
* FUNCTION OPERATOR pgdms_did_pgdms_ref_lt (a pgdms_did, b pgdms_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_did_pgdms_ref_le (a pgdms_did, b pgdms_ref)
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
* OPERATOR pgdms_did <= pgdms_ref
*/
CREATE OPERATOR pg_catalog. <= (
PROCEDURE = pgdms_did_pgdms_ref_le, LEFTARG = pgdms_did, RIGHTARG = pgdms_ref);
/*
* FUNCTION OPERATOR pgdms_did_pgdms_ref_lt (a pgdms_did, b pgdms_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_did_pgdms_ref_ge (a pgdms_did, b pgdms_ref)
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
* OPERATOR pgdms_did >= pgdms_ref
*/
CREATE OPERATOR pg_catalog. >= (
PROCEDURE = pgdms_did_pgdms_ref_ge, LEFTARG = pgdms_did, RIGHTARG = pgdms_ref);
/*
* FUNCTION OPERATOR pgdms_did_pgdms_ref_lt (a pgdms_did, b pgdms_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_did_pgdms_ref_gt (a pgdms_did, b pgdms_ref)
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
* OPERATOR pgdms_did > pgdms_ref
*/
CREATE OPERATOR pg_catalog. > (
PROCEDURE = pgdms_did_pgdms_ref_gt, LEFTARG = pgdms_did, RIGHTARG = pgdms_ref);
/*
* FUNCTION OPERATOR pgdms_did_pgdms_ref_lt (a pgdms_did, b pgdms_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_did_ref_cmp (a pgdms_did, b pgdms_ref)
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
* FUNCTION OPERATOR pgdms_ref_pgdms_did_eq (a pgdms_ref, b pgdms_did)
*/
CREATE OR REPLACE FUNCTION public.pgdms_ref_pgdms_did_eq (a pgdms_ref, b pgdms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  raise notice 'note--212';
  RETURN a.family = b.family and a.id = b.id;
END;
$BODY$;
/*
* OPERATOR pgdms_ref = pgdms_did
*/
CREATE OPERATOR pg_catalog. = (
PROCEDURE = pgdms_ref_pgdms_did_eq, LEFTARG = pgdms_ref, RIGHTARG = pgdms_did);
/*
* FUNCTION OPERATOR pgdms_ref_pgdms_did_lt (a pgdms_ref, b pgdms_did)
*/
CREATE OR REPLACE FUNCTION public.pgdms_ref_pgdms_did_lt (a pgdms_ref, b pgdms_did)
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
* OPERATOR pgdms_ref < pgdms_did
*/
CREATE OPERATOR pg_catalog. < (
PROCEDURE = pgdms_ref_pgdms_did_lt, LEFTARG = pgdms_ref, RIGHTARG = pgdms_did);
/*
* FUNCTION OPERATOR pgdms_ref_pgdms_did_lt (a pgdms_ref, b pgdms_did)
*/
CREATE OR REPLACE FUNCTION public.pgdms_ref_pgdms_did_le (a pgdms_ref, b pgdms_did)
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
* OPERATOR pgdms_ref <= pgdms_did
*/
CREATE OPERATOR pg_catalog. <= (
PROCEDURE = pgdms_ref_pgdms_did_le, LEFTARG = pgdms_ref, RIGHTARG = pgdms_did);
/*
* FUNCTION OPERATOR pgdms_ref_pgdms_did_lt (a pgdms_ref, b pgdms_did)
*/
CREATE OR REPLACE FUNCTION public.pgdms_ref_pgdms_did_ge (a pgdms_ref, b pgdms_did)
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
* OPERATOR pgdms_ref >= pgdms_did
*/
CREATE OPERATOR pg_catalog. >= (
PROCEDURE = pgdms_ref_pgdms_did_ge, LEFTARG = pgdms_ref, RIGHTARG = pgdms_did);
/*
* FUNCTION OPERATOR pgdms_ref_pgdms_did_lt (a pgdms_ref, b pgdms_did)
*/
CREATE OR REPLACE FUNCTION public.pgdms_ref_pgdms_did_gt (a pgdms_ref, b pgdms_did)
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
* OPERATOR pgdms_ref > pgdms_did
*/
CREATE OPERATOR pg_catalog. > (
PROCEDURE = pgdms_ref_pgdms_did_gt, LEFTARG = pgdms_ref, RIGHTARG = pgdms_did);
/*
* FUNCTION OPERATOR pgdms_ref_pgdms_did_lt (a pgdms_ref, b pgdms_did)
*/
CREATE OR REPLACE FUNCTION public.pgdms_ref_did_cmp (a pgdms_ref, b pgdms_did)
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
* OPERATOR family pgdms_ops 
*/
ALTER OPERATOR family pgdms_ops
USING btree
  ADD -- cross-type comparisons pgdms_did vs pgdms_ref
  OPERATOR 1 < (pgdms_did,
    pgdms_ref),
  OPERATOR 2 <= (pgdms_did,
    pgdms_ref),
  OPERATOR 3 = (pgdms_did,
    pgdms_ref),
  OPERATOR 4 >= (pgdms_did,
    pgdms_ref),
  OPERATOR 5 > (pgdms_did,
    pgdms_ref),
  FUNCTION 1 public.pgdms_did_ref_cmp (pgdms_did,
    pgdms_ref), -- cross-type comparisons pgdms_ref vs pgdms_did
  OPERATOR 1 < (pgdms_ref,
    pgdms_did),
  OPERATOR 2 <= (pgdms_ref,
    pgdms_did),
  OPERATOR 3 = (pgdms_ref,
    pgdms_did),
  OPERATOR 4 >= (pgdms_ref,
    pgdms_did),
  OPERATOR 5 > (pgdms_ref,
    pgdms_did),
  FUNCTION 1 public.pgdms_ref_did_cmp (pgdms_ref,
    pgdms_did);
/*
* FUNCTION OPERATOR pgdms_didup_text_eq (a pgdms_family_ref, b text)
*/
CREATE OR REPLACE FUNCTION public.pgdms_didup_text_eq (a pgdms_family_ref, b text)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN a.family::text = substring(b, 1, 36);
END;
$BODY$;
/*
* OPERATOR pgdms_family_ref = text
*/
CREATE OPERATOR pg_catalog. = (
PROCEDURE = pgdms_didup_text_eq, LEFTARG = pgdms_family_ref, RIGHTARG = text, COMMUTATOR = =, NEGATOR = <>, HASHES, MERGES);
/*
* FUNCTION OPERATOR pgdms_did_uuid_eq (a pgdms_did, b uuid)
*/
CREATE OR REPLACE FUNCTION public.pgdms_did_uuid_eq (a pgdms_did, b uuid)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN a.id = b;
END;
$BODY$;
/*
* OPERATOR pgdms_did = uuid
*/
CREATE OPERATOR pg_catalog. = (
PROCEDURE = pgdms_did_uuid_eq, LEFTARG = pgdms_did, RIGHTARG = uuid, COMMUTATOR = =, NEGATOR = <>, HASHES, MERGES);
/*
* FUNCTION OPERATOR pgdms_didn_text_eq (a pgdms_ref, b text)
*/
CREATE OR REPLACE FUNCTION public.pgdms_didn_text_eq (a pgdms_ref, b text)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN a.family::text = substring(b, 1, 36) and a.id::text = substring(b, 38, 70);
END;
$BODY$;
/*
* OPERATOR pgdms_ref = text
*/
CREATE OPERATOR pg_catalog. = (
PROCEDURE = pgdms_didn_text_eq, LEFTARG = pgdms_ref, RIGHTARG = text, COMMUTATOR = =, NEGATOR = <>, HASHES, MERGES);
/*
* FUNCTION OPERATOR pgdms_did_pgdms_status_eq (a pgdms_did, b pgdms_status)
*/
CREATE OR REPLACE FUNCTION public.pgdms_did_pgdms_status_eq (a pgdms_did, b pgdms_status)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN a.status = b;
END;
$BODY$;
/*
* OPERATOR pgdms_did = pgdms_status
*/
CREATE OPERATOR pg_catalog. = (
PROCEDURE = pgdms_did_pgdms_status_eq, LEFTARG = pgdms_did, RIGHTARG = pgdms_status, COMMUTATOR = =, NEGATOR = <>, HASHES, MERGES);
/*
* FUNCTION CAST pgdms_did (a uuid)
*/
CREATE OR REPLACE FUNCTION public.pgdms_did (a uuid)
  RETURNS pgdms_did
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
DECLARE
  ret pgdms_did;
BEGIN
  ret.id = uuid_generate_v4 ();
  ret.created = now();
  ret.ac [ 0 ] = (now(), (
      SELECT
        USER),
      'created'::pgdms_actiontype,
      NULL)::pgdms_action;
  IF (a IS NULL) THEN
    ret.family = ret.id;
  ELSE
    ret.family = a;
  END IF;
  ret.status = 'work'::pgdms_status;
  RETURN ret;
END;
$BODY$;
/*
* CAST uuid => pgdms_did
*/
CREATE CAST(
  uuid
AS pgdms_did)
WITH FUNCTION public.pgdms_did (uuid) AS
ASSIGNMENT;

/*
* FUNCTION CAST pgdms_did (a text)
*/
CREATE OR REPLACE FUNCTION public.pgdms_did (a text)
  RETURNS pgdms_did
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN public.pgdms_did ((public.pgdms_family_ref (a)).id);
END;
$BODY$;

/*
* CAST text => pgdms_did
*/
CREATE CAST(
  text
AS pgdms_did)
WITH FUNCTION public.pgdms_did (text) AS ASSIGNMENT;
/*
* FUNCTION CAST pgdms_family_ref (a uuid) 
*/
CREATE OR REPLACE FUNCTION public.pgdms_family_ref (a uuid)
  RETURNS pgdms_family_ref
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
DECLARE
  ret pgdms_family_ref;
BEGIN
  ret.family = a;
  RETURN ret;
END;
$BODY$;
/*
* CAST uuid =>  pgdms_family_ref
*/
CREATE CAST(
  uuid
AS pgdms_family_ref)
WITH FUNCTION public.pgdms_family_ref (uuid) AS
ASSIGNMENT;

/*
* FUNCTION CAST pgdms_family_ref (a text)
*/
CREATE OR REPLACE FUNCTION public.pgdms_family_ref (a text)
  RETURNS pgdms_family_ref
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
DECLARE
  ret pgdms_family_ref;
BEGIN
  ret.family = substring(a, 1, 36)::uuid;
  RETURN ret;
END;
$BODY$;
/*
* FUNCTION OPERATOR pgdms_did_text_eq (a pgdms_did, b text)
*/
CREATE OR REPLACE FUNCTION public.pgdms_did_text_eq (a pgdms_did, b text)
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
* OPERATOR pgdms_did = text
*/
CREATE OPERATOR pg_catalog. = (
PROCEDURE = pgdms_did_text_eq, LEFTARG = pgdms_did, RIGHTARG = text, COMMUTATOR = =, NEGATOR = <>, HASHES, MERGES);
/*
* CAST text => pgdms_family_ref  
*/
CREATE CAST(
  text
AS pgdms_family_ref)
WITH FUNCTION public.pgdms_family_ref (text) AS
ASSIGNMENT;

/*
* FUNCTION CAST pgdms_ref (a text)
*/
CREATE OR REPLACE FUNCTION public.pgdms_ref (a text)
  RETURNS pgdms_ref
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
DECLARE
  ret pgdms_ref;
BEGIN
  ret.family = substring(a, 1, 36)::uuid;
  ret.id = substring(a, 38, 70)::uuid;
  RETURN ret;
END;
$BODY$;

/*
* CAST text => pgdms_ref  
*/
CREATE CAST(
  text
AS pgdms_ref)
WITH FUNCTION public.pgdms_ref (text) AS ASSIGNMENT;
/*
* FUNCTION CAST pgdms_uuid (a pgdms_did)
*/
CREATE OR REPLACE FUNCTION public.pgdms_uuid (a pgdms_did)
  RETURNS uuid
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN a.id;
END;
$BODY$;
/*
* CAST pgdms_did => uuid  
*/
CREATE CAST(
  pgdms_did
AS uuid)
WITH FUNCTION public.pgdms_uuid (pgdms_did) AS
ASSIGNMENT;

/*
* FUNCTION CAST pgdms_uuid (a pgdms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_uuid (a pgdms_family_ref)
  RETURNS uuid
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN a.id;
END;
$BODY$;

/*
* CAST pgdms_family_ref => uuid 
*/
CREATE CAST(
  pgdms_family_ref
AS uuid)
WITH FUNCTION public.pgdms_uuid (pgdms_family_ref) AS ASSIGNMENT;
/*
* FUNCTION CAST pgdms_text (a pgdms_family_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_text (a pgdms_family_ref)
  RETURNS text
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN (a.id)::text;
END;
$BODY$;
/*
* CAST pgdms_family_ref => text  
*/
CREATE CAST(
  pgdms_family_ref
AS text)
WITH FUNCTION public.pgdms_text (pgdms_family_ref) AS
ASSIGNMENT;

/*
* FUNCTION CAST pgdms_text (a pgdms_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_text (a pgdms_ref)
  RETURNS text
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN (a.family)::text || ',' || (a.id)::text;
END;
$BODY$;

/*
* CAST pgdms_ref => text  
*/
CREATE CAST(
  pgdms_ref
AS text)
WITH FUNCTION public.pgdms_text (pgdms_ref) AS ASSIGNMENT;
/*
* FUNCTION CAST pgdms_text (a pgdms_did)
*/
CREATE OR REPLACE FUNCTION public.pgdms_text (a pgdms_did)
  RETURNS text
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN (a.family)::text || ',' || (a.id)::text;
END;
$BODY$;
/*
* CAST pgdms_did => text 
*/
CREATE CAST(
  pgdms_did
AS text)
WITH FUNCTION public.pgdms_text (pgdms_did) AS
ASSIGNMENT;

/*
* FUNCTION CAST pgdms_uuid (a pgdms_ref)
*/
CREATE OR REPLACE FUNCTION public.pgdms_uuid (a pgdms_ref)
  RETURNS uuid
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN a.id;
END;
$BODY$;

/*
* CAST pgdms_ref => uuid 
*/
CREATE CAST(
  pgdms_ref
AS uuid)
WITH FUNCTION public.pgdms_uuid (pgdms_ref) AS ASSIGNMENT;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pgdms_setstatus_document (entity text, did pgdms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  EXECUTE 'UPDATE ' || entity || '
                                    SET ' || pgdms_get_pk (entity) || '.status = ''archival''::pgdms_status, ' || pgdms_get_pk (entity) || '.valid_until  = now()  
                                    WHERE (' || entity || '.' || pgdms_get_pk (entity) || ').family = ''' || did.family || '''::uuid and (' || entity || '.' || pgdms_get_pk (entity) || ').status = ''document''::pgdms_status ';
  EXECUTE 'UPDATE ' || entity || '
                                    SET ' || pgdms_get_pk (entity) || '.status = ''document''::pgdms_status, ' || pgdms_get_pk (entity) || '.valid_from   = now() 
                                    WHERE (' || entity || '.' || pgdms_get_pk (entity) || ').id = ''' || did.id || '''::uuid';
  RETURN TRUE;
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pgdms_set_hash (entity text, did pgdms_did)
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
      AND a.attname <> pgdms_get_pk (entity)) || '))::uuid from ' || entity || ' 
                                	WHERE (' || entity || '.' || pgdms_get_pk (entity) || ').id = ''' || did.id || '''::uuid' INTO h;
  EXECUTE 'UPDATE ' || entity || '
                                   SET ' || pgdms_get_pk (entity) || '.hash = ''' || h || '''
                                   WHERE (' || entity || '.' || pgdms_get_pk (entity) || ').id = ''' || did.id || '''::uuid';
  RETURN;
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pgdms_change_status (entity text, did pgdms_did, status pgdms_status)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  IF (did.status = 'work'::pgdms_status) THEN
    IF (status = 'work'::pgdms_status) THEN
      RETURN TRUE;
    END IF;
    IF (status = 'project'::pgdms_status OR status = 'document'::pgdms_status) THEN
      PERFORM
        pgdms_set_hash (entity,
          did);
    END IF;
    IF (status = 'document'::pgdms_status) THEN
      RETURN pgdms_setstatus_document (entity,
        did);
    END IF;
  END IF;
  IF (did.status = 'project'::pgdms_status) THEN
    IF (status = 'work'::pgdms_status) THEN
      RETURN FALSE;
    END IF;
    IF (status = 'project'::pgdms_status) THEN
      RETURN TRUE;
    END IF;
    IF (status = 'document'::pgdms_status) THEN
      RETURN pgdms_setstatus_document (entity,
        did);
    END IF;
  END IF;
  IF (did.status = 'document'::pgdms_status) THEN
    IF (status = 'work'::pgdms_status) THEN
      RETURN FALSE;
    END IF;
    IF (status = 'project'::pgdms_status) THEN
      RETURN FALSE;
    END IF;
    IF (status = 'document'::pgdms_status) THEN
      RETURN TRUE;
    END IF;
  END IF;
  EXECUTE 'UPDATE ' || entity || '
                                	SET ' || pgdms_get_pk (entity) || '.status = ''' || status || ''' 
                                	WHERE (' || entity || '.' || pgdms_get_pk (entity) || ').id = ''' || did.id || '''::uuid';
  RETURN TRUE;
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pgdms_change_status (entity text, did pgdms_did, status pgdms_status)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  IF (did.status = 'work'::pgdms_status) THEN
    IF (status = 'work'::pgdms_status) THEN
      RETURN TRUE;
    END IF;
    IF (status = 'project'::pgdms_status OR status = 'document'::pgdms_status) THEN
      PERFORM
        pgdms_set_hash (entity,
          did);
    END IF;
    IF (status = 'document'::pgdms_status) THEN
      RETURN pgdms_setstatus_document (entity,
        did);
    END IF;
  END IF;
  IF (did.status = 'project'::pgdms_status) THEN
    IF (status = 'work'::pgdms_status) THEN
      RETURN FALSE;
    END IF;
    IF (status = 'project'::pgdms_status) THEN
      RETURN TRUE;
    END IF;
    IF (status = 'document'::pgdms_status) THEN
      RETURN pgdms_setstatus_document (entity,
        did);
    END IF;
  END IF;
  IF (did.status = 'document'::pgdms_status) THEN
    IF (status = 'work'::pgdms_status) THEN
      RETURN FALSE;
    END IF;
    IF (status = 'project'::pgdms_status) THEN
      RETURN FALSE;
    END IF;
    IF (status = 'document'::pgdms_status) THEN
      RETURN TRUE;
    END IF;
  END IF;
  EXECUTE 'UPDATE ' || entity || '
                                	SET ' || pgdms_get_pk (entity) || '.status = ''' || status || ''' 
                                	WHERE (' || entity || '.' || pgdms_get_pk (entity) || ').id = ''' || did.id || '''::uuid';
  RETURN TRUE;
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pgdms_set_action (entity text, did pgdms_did, action pgdms_actiontype, note text)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
DECLARE
  f boolean;
BEGIN
  IF (action = 'created'::pgdms_actiontype) THEN
    RAISE NOTICE 'Действие ''created'' создается автоматически';
    RETURN FALSE;
  END IF;
  EXECUTE 'UPDATE ' || entity || '
                                   SET ' || pgdms_get_pk (entity) || '.ac = (' || entity || '.' || pgdms_get_pk (entity) || ').ac || (''' || now() || ''',''' || (
    SELECT
      USER) || ''', ''' || action || '''::pgdms_actiontype ,' || COALESCE('''' || note || '''', 'null') || ')::pgdms_action
                                   WHERE (' || entity || '.' || pgdms_get_pk (entity) || ').id = ''' || did.id || '''::uuid';
  IF (action = 'agreed'::pgdms_actiontype) THEN
    IF (did.status = 'work'::pgdms_status) THEN
      f = pgdms_change_status (entity,
        did,
        'project'::pgdms_status);
    END IF;
    RETURN TRUE;
  END IF;
  IF (action = 'approved'::pgdms_actiontype) THEN
    IF (did.status = 'project'::pgdms_status) THEN
      f = pgdms_change_status (entity,
        did,
        'document'::pgdms_status);
    END IF;
    RETURN TRUE;
  END IF;
  RETURN TRUE;
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pgdms_get_did (entity text, k text)
  RETURNS pgdms_did
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
DECLARE
  did pgdms_did;
BEGIN
  EXECUTE 'SELECT (' || pgdms_get_pk (entity) || ').id FROM ' || entity || ' WHERE (' || entity || '.' || pgdms_get_pk (entity) || ').id = ''' || substring(k, 1, 36) || '''::uuid' INTO did.id;
  EXECUTE 'SELECT (' || pgdms_get_pk (entity) || ').family FROM ' || entity || ' WHERE (' || entity || '.' || pgdms_get_pk (entity) || ').id = ''' || substring(k, 1, 36) || '''::uuid' INTO did.family;
  EXECUTE 'SELECT (' || pgdms_get_pk (entity) || ').status FROM ' || entity || ' WHERE (' || entity || '.' || pgdms_get_pk (entity) || ').id = ''' || substring(k, 1, 36) || '''::uuid' INTO did.status;
  EXECUTE 'SELECT (' || pgdms_get_pk (entity) || ').created FROM ' || entity || ' WHERE (' || entity || '.' || pgdms_get_pk (entity) || ').id = ''' || substring(k, 1, 36) || '''::uuid' INTO did.created;
  EXECUTE 'SELECT (' || pgdms_get_pk (entity) || ').hash FROM ' || entity || ' WHERE (' || entity || '.' || pgdms_get_pk (entity) || ').id = ''' || substring(k, 1, 36) || '''::uuid' INTO did.hash;
  EXECUTE 'SELECT (' || pgdms_get_pk (entity) || ').valid_from FROM ' || entity || ' WHERE (' || entity || '.' || pgdms_get_pk (entity) || ').id = ''' || substring(k, 1, 36) || '''::uuid' INTO did.valid_from;
  EXECUTE 'SELECT (' || pgdms_get_pk (entity) || ').valid_until FROM ' || entity || ' WHERE (' || entity || '.' || pgdms_get_pk (entity) || ').id = ''' || substring(k, 1, 36) || '''::uuid' INTO did.valid_until;
  EXECUTE 'SELECT (' || pgdms_get_pk (entity) || ').ac FROM ' || entity || ' WHERE (' || entity || '.' || pgdms_get_pk (entity) || ').id = ''' || substring(k, 1, 36) || '''::uuid' INTO did.ac;
  RETURN did;
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pgdms_set_action (entity text, k text, action pgdms_actiontype, note text)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN public.pgdms_set_action (entity,
    pgdms_get_did (entity,
      k),
    action,
    note);
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pgdms_get_actions (a pgdms_did)
  RETURNS text
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN pgdms_to_text ((a).ac);
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pgdms_get_status (a pgdms_did)
  RETURNS text
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN pgdms_to_text ((a).status);
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pgdms_get_hash (a pgdms_did)
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
CREATE OR REPLACE FUNCTION public.pgdms_is_document (a pgdms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN (a).status = 'document'::pgdms_status;
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pgdms_is_document (a pgdms_did, ts timestamp WITH time zone)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
BEGIN
  RETURN (((a).status = 'document'::pgdms_status
      OR (a).status = 'archival'::pgdms_status)
    AND (a).valid_from <= ts
    AND ((a).valid_until > ts
      OR (a).valid_until IS NULL));
END;
$BODY$;
/*
* FUNCTION 
*/
CREATE OR REPLACE FUNCTION public.pgdms_is_family (a pgdms_did, f pgdms_did)
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
CREATE OR REPLACE FUNCTION public.pgdms_is_family (a pgdms_did, f text)
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
CREATE OR REPLACE FUNCTION public.pgdms_is_last (entity text, a pgdms_did)
  RETURNS boolean
  LANGUAGE 'plpgsql' COST 100 VOLATILE
AS $BODY$
DECLARE
  f uuid;
BEGIN
  EXECUTE 'SELECT (' || entity || '.' || pgdms_get_pk (entity) || ').id 
                            from ' || entity || ' where (' || entity || '.' || pgdms_get_pk (entity) || ').family = ''' || (a).family || ''' order by (' || entity || '.' || pgdms_get_pk (entity) || ').family desc limit 1' INTO f;
  IF ((a).id = f) THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$BODY$;
