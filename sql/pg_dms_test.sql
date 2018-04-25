CREATE EXTENSION pg_dms CASCADE;
CREATE EXTENSION pg_abris CASCADE;



CREATE TABLE public.test (
  KEY pg_dms_id NOT NULL DEFAULT uuid_generate_v4(),
  num integer,
  CONSTRAINT d_pkey PRIMARY KEY (KEY)
)
WITH (OIDS = FALSE) TABLESPACE pg_default;

INSERT INTO public.test (num) VALUES (1);

INSERT INTO public.test (num)  VALUES (2);

INSERT INTO public.test (KEY, num)
  VALUES (('73a0d05a-d681-4bb3-9e31-9f52ee938ad2,eec4a453-4a90-49e9-8044-b6b51311ad5a')::pg_dms_id, 3);

INSERT INTO public.test (KEY, num)
  VALUES ('3ea227be-9932-4fb1-b47a-84c1851b419a,7cea1a82-213d-41aa-97f2-80138b538ca6', 4);

INSERT INTO public.test (KEY, num)
  VALUES ('ae060476-a0c1-4ec1-993f-f71ba3882796,29a1e5f1-33f8-477b-958d-3868edfbbfcf', 5);

INSERT INTO public.test (KEY, num)
  VALUES ('ae060476-a0c1-4ec1-993f-f71ba3882796,381adf5e-5ec2-4855-a25d-b22ef99fcfa8', 6);

INSERT INTO public.test (KEY, num)
  VALUES ('ae060476-a0c1-4ec1-993f-f71ba3882796,cc8a3b5b-9899-4038-ac01-67a6b0450eff', 7);

select * from test order by key;

select * from test where key > '73a0d05a-d681-4bb3-9e31-9f52ee938ad2,eec4a453-4a90-49e9-8044-b6b51311ad5a';
select * from test where key >= '73a0d05a-d681-4bb3-9e31-9f52ee938ad2,eec4a453-4a90-49e9-8044-b6b51311ad5a';
select * from test where key = '73a0d05a-d681-4bb3-9e31-9f52ee938ad2,eec4a453-4a90-49e9-8044-b6b51311ad5a';
select * from test where key < '73a0d05a-d681-4bb3-9e31-9f52ee938ad2,eec4a453-4a90-49e9-8044-b6b51311ad5a';
select * from test where key <= '73a0d05a-d681-4bb3-9e31-9f52ee938ad2,eec4a453-4a90-49e9-8044-b6b51311ad5a';


select pg_dms_getstatus(key), num from test;

UPDATE test SET key=pg_dms_setstatus(key,1) WHERE num = 5;

select pg_dms_getstatus(key), num from test;


UPDATE test SET key=pg_dms_setaction(key, 1, (SELECT oid from pg_class where relname = 'test'), '73a0d05a-d681-4bb3-9e31-9f52ee938ad2'::uuid) WHERE num = 3;

select pg_dms_getaction(key), num from test;



select a.name, au.rolname, "date", c.relname, reason_key from unnest((select pg_dms_getaction(key) from test where num = 3) ) as t
left join action_list a on t.type = a.key 
left join pg_catalog.pg_authid au on t.user = au.oid
left join pg_catalog.pg_class c on t.reason = c.oid;














/*

CREATE TABLE public.d (
  KEY pg_dms_did NOT NULL,
  num integer,
  CONSTRAINT d_pkey PRIMARY KEY (KEY))
WITH (OIDS = FALSE) TABLESPACE pg_default;

CREATE SEQUENCE public.dup_key_seq
  INCREMENT 1 START 1
  MINVALUE 1
  MAXVALUE 2147483647
  CACHE 1;

--CREATE INDEX products_idx
--    ON public.d USING btree
--    (key)  
--    TABLESPACE pg_default;


CREATE TABLE public.dup (
  KEY integer NOT NULL DEFAULT nextval('dup_key_seq'::regclass),
  d pg_dms_family_ref,
  name text COLLATE pg_catalog. "default",
  CONSTRAINT dup_pkey PRIMARY KEY (KEY),
  CONSTRAINT dup_d_fkey FOREIGN KEY (d) REFERENCES public.d (KEY) MATCH SIMPLE ON
  UPDATE
    NO ACTION ON DELETE NO ACTION
)
  WITH (OIDS = FALSE) TABLESPACE pg_default;

CREATE SEQUENCE public.dn_key_seq
  INCREMENT 1 START 1
  MINVALUE 1
  MAXVALUE 2147483647
  CACHE 1;


CREATE TABLE public.dn (
  KEY integer NOT NULL DEFAULT nextval('dn_key_seq'::regclass),
  d pg_dms_ref,
  name text COLLATE pg_catalog. "default",
  CONSTRAINT dn_pkey PRIMARY KEY (KEY)
  , CONSTRAINT dn_d_fkey FOREIGN KEY (d) REFERENCES public.d (KEY) MATCH SIMPLE ON
  UPDATE
  NO ACTION ON DELETE NO ACTION
)
  WITH (OIDS = FALSE) TABLESPACE pg_default;

--CREATE INDEX dn_idx_d
--    ON public.dn USING btree
--    (d)
--    TABLESPACE pg_default;


INSERT INTO public.d (KEY, num)
  VALUES (null::uuid, 1);

INSERT INTO public.d (KEY, num)
  VALUES ((
      SELECT
        key::uuid
      FROM
        public.d
      WHERE
        num = 1), 2);

SELECT
  public.pg_dms_set_action ('public.d', (
      SELECT
        KEY
      FROM
        d
      WHERE
        num = 2), 'created'::pg_dms_actiontype, 'Yra');

SELECT
  public.pg_dms_set_action ('public.d', (
      SELECT
        KEY
      FROM
        d
      WHERE
        num = 2), 'agreed'::pg_dms_actiontype, '--');

SELECT
  public.pg_dms_set_action ('public.d', (
      SELECT
        KEY
      FROM
        d
      WHERE
        num = 2), 'approved'::pg_dms_actiontype, '---');

INSERT INTO public.d (KEY, num)
  VALUES ((
      SELECT
        key::uuid
      FROM
        public.d
      WHERE
        num = 1), 3);

SELECT
  public.pg_dms_set_action ('public.d', (
      SELECT
        KEY
      FROM
        d
      WHERE
        num = 3), 'agreed'::pg_dms_actiontype, '--');

SELECT
  public.pg_dms_set_action ('public.d', (
      SELECT
        KEY
      FROM
        d
      WHERE
        num = 3), 'approved'::pg_dms_actiontype, NULL);



select * from d;



INSERT INTO public.dup (d, name)
  VALUES ((
      SELECT
        key::uuid
      FROM
        public.d
      WHERE
        num = 1), 'a1');

INSERT INTO public.dn (d, name)
  VALUES ((
      SELECT
        key::text
      FROM
        public.d
      WHERE
        num = 1), 'a1');
INSERT INTO public.dn (d, name)
  VALUES ((
      SELECT
        key::text
      FROM
        public.d
      WHERE
        num = 2), 'a2');
INSERT INTO public.dn (d, name)
  VALUES ((
      SELECT
        key::text
      FROM
        public.d
      WHERE
        num = 3), 'a3');
        
------------------------------------------------
SELECT   d.num FROM  d,  dup WHERE  d.key = dup.d;


SELECT   d.num FROM   d,   dup WHERE   dup.d = d.key;

select d.num from d  left join dup on  d.key = dup.d;


SELECT   d.num FROM   d,   dn WHERE   d.key = dn.d;


SELECT   d.num FROM   d,   dn WHERE   dn.d = d.key;

INSERT INTO public.d (KEY, num)
  VALUES ('2604bebd-3369-423c-be17-9e27e50c823b'::uuid, 4);

SELECT
  count(*)
FROM
  public.d;

SELECT
  num
FROM
  public.d
WHERE
  KEY = 'document'::pg_dms_status;

--Вывод дествий по всем строкам
--Результат с плановой ошибкой из-за времени	
--SELECT pg_dms_get_actions(key),pg_dms_get_hash(key),pg_dms_get_status(key) FROM d;	
--Вывод статуса строк
SELECT
  pg_dms_get_status (KEY)
FROM
  d;

--Вывод только действующих документов
SELECT
  num,
  pg_dms_get_status (KEY)
FROM
  d
WHERE
  pg_dms_is_document (KEY);

--Вывод только  документов на дату
--SELECT num, pg_dms_get_status(key) FROM d WHERE pg_dms_is_document(key, now()-'20 milliseconds'::interval);
--Вывод записей одного семейства
SELECT
  num,
  pg_dms_get_status (KEY)
FROM
  d
WHERE
  pg_dms_is_family (KEY, (
      SELECT
        KEY
      FROM
        d
      WHERE
        num = 1));

SELECT
  num,
  pg_dms_get_status (KEY)
FROM
  d
WHERE
  pg_dms_is_family (KEY, (
      SELECT
        key::text
      FROM
        d
      WHERE
        num = 1));

--Вывод последных записей
SELECT
  num
FROM
  d
WHERE
  pg_dms_is_last ('public.d', KEY);

*/