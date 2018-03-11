-- complain IF script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pgdms" to load this file. \quit

CREATE FUNCTION hello()
RETURNS text
LANGUAGE plpgsql IMMUTABLE STRICT
  AS $BODY$
    BEGIN
    RETURN 'Hello, World!';
    END;
  $BODY$;
  
CREATE TYPE public.pgdms_status AS ENUM
    ('work', 'progect', 'document');  

CREATE TYPE public.pgdms_did AS
(
    family uuid,
    key uuid,
    status pgdms_status
);

CREATE TYPE public.pgdms_didup AS
(
    key uuid
);

CREATE TYPE public.pgdms_didn AS
(
    key uuid
);
 
CREATE OR REPLACE FUNCTION public.pgdms_did_pgdms_didup_eq(a pgdms_did, b pgdms_didup)
    RETURNS boolean
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
BEGIN
  IF(a.family = b.key and a.status = 'document'::pgdms_status) THEN return true;
  else return false;
  END IF;
END;
$BODY$;

CREATE OPERATOR pg_catalog.=(
  PROCEDURE = pgdms_did_pgdms_didup_eq,
  LEFTARG = pgdms_did,
  RIGHTARG = pgdms_didup,
  COMMUTATOR = =,
  NEGATOR = <>,
  HASHES,
  MERGES);

CREATE OR REPLACE FUNCTION public.pgdms_did_pgdms_didn_eq(a pgdms_did, b pgdms_didn)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE 
AS $BODY$
BEGIN
  IF(a.key = b.key) THEN return true;
  else return false;
  END IF;
END;
$BODY$;

CREATE OPERATOR pg_catalog.=(
  PROCEDURE = pgdms_did_pgdms_didn_eq,
  LEFTARG = pgdms_did,
  RIGHTARG = pgdms_didn,
  COMMUTATOR = =,
  NEGATOR = <>,
  HASHES,
  MERGES);
  
CREATE OR REPLACE FUNCTION public.pgdms_did_pgdms_did_eq(a pgdms_did, b pgdms_did)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE 
AS $BODY$
BEGIN
  IF(a.key = b.key) THEN return true;
  else return false;
  END IF;
END;
$BODY$;

CREATE OPERATOR pg_catalog.=(
  PROCEDURE = pgdms_did_pgdms_did_eq,
  LEFTARG = pgdms_did,
  RIGHTARG = pgdms_did,
  COMMUTATOR = =,
  NEGATOR = <>,
  HASHES,
  MERGES);

CREATE OR REPLACE FUNCTION public.pgdms_did_pgdms_status_eq(a pgdms_did, b pgdms_status)
    RETURNS boolean
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
BEGIN
  IF(a.status = b) THEN return true;
  else return false;
  END IF;
END;
$BODY$;

CREATE OPERATOR pg_catalog.=(
  PROCEDURE = pgdms_did_pgdms_status_eq,
  LEFTARG = pgdms_did,
  RIGHTARG = pgdms_status,
  COMMUTATOR = =,
  NEGATOR = <>,
  HASHES,
  MERGES);

CREATE OR REPLACE FUNCTION public.pgdms_did(
	a uuid)
    RETURNS pgdms_did
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE 
AS $BODY$
DECLARE
  ret pgdms_did;
BEGIN
  ret.key = uuid_generate_v4();
  IF (a is null) THEN
    ret.family = ret.key;
    --nado ispravit'
    ret.status = 'work'::pgdms_status;
  ELSE 
    ret.family = a;
    ret.status = 'document'::pgdms_status;
  END IF;  
  --ret.status = 0;
  return ret;
END;
$BODY$;  
  
CREATE CAST (uuid AS pgdms_did)
	WITH FUNCTION public.pgdms_did(uuid)
	AS ASSIGNMENT;  

CREATE OR REPLACE FUNCTION public.pgdms_didup(
	a uuid)
    RETURNS pgdms_didup
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE 
AS $BODY$
DECLARE
  ret pgdms_didup;
BEGIN
  ret.key = a;
  return ret;
END;
$BODY$;  
  
CREATE CAST (uuid AS pgdms_didup)
	WITH FUNCTION public.pgdms_didup(uuid)
	AS ASSIGNMENT;  

CREATE OR REPLACE FUNCTION public.pgdms_didn(
	a uuid)
    RETURNS pgdms_didn
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE 
AS $BODY$
DECLARE
  ret pgdms_didn;
BEGIN
  ret.key = a;
  return ret;
END;
$BODY$;  
  
CREATE CAST (uuid AS pgdms_didn)
	WITH FUNCTION public.pgdms_didn(uuid)
	AS ASSIGNMENT;  

CREATE OR REPLACE FUNCTION public.pgdms_uuid(
	a pgdms_did)
    RETURNS uuid
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE 
AS $BODY$
BEGIN
  return a.key;
END;
$BODY$;  
  
CREATE CAST (pgdms_did AS uuid)
	WITH FUNCTION public.pgdms_uuid(pgdms_did)
	AS ASSIGNMENT;  

CREATE OR REPLACE FUNCTION public.pgdms_changestatus(
	entity text,
	did pgdms_did,
	status pgdms_status)
    RETURNS boolean
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$

BEGIN
  EXECUTE 'UPDATE ' || entity || '
	SET key = ' ||status || ';
END;

$BODY$;


  