CREATE EXTENSION pgdms CASCADE;

SELECT
  hello ();

CREATE TABLE public.d (
  KEY pgdms_did NOT NULL,
  num integer,
  CONSTRAINT d_pkey PRIMARY KEY (KEY))
WITH (OIDS = FALSE) TABLESPACE pg_default;

CREATE SEQUENCE public.dup_key_seq
  INCREMENT 1 START 1
  MINVALUE 1
  MAXVALUE 2147483647
  CACHE 1;

CREATE TABLE public.dup (
  KEY integer NOT NULL DEFAULT nextval('dup_key_seq'::regclass),
  d pgdms_family_ref,
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
  d pgdms_ref,
  name text COLLATE pg_catalog. "default",
  CONSTRAINT dn_pkey PRIMARY KEY (KEY),
  CONSTRAINT dn_d_fkey FOREIGN KEY (d) REFERENCES public.d (KEY) MATCH SIMPLE ON
  UPDATE
    NO ACTION ON DELETE NO ACTION
)
  WITH (OIDS = FALSE) TABLESPACE pg_default;

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
  public.pgdms_set_action ('public.d', (
      SELECT
        KEY
      FROM
        d
      WHERE
        num = 2), 'created'::pgdms_actiontype, 'Yra');

SELECT
  public.pgdms_set_action ('public.d', (
      SELECT
        KEY
      FROM
        d
      WHERE
        num = 2), 'agreed'::pgdms_actiontype, '--');

SELECT
  public.pgdms_set_action ('public.d', (
      SELECT
        KEY
      FROM
        d
      WHERE
        num = 2), 'approved'::pgdms_actiontype, '---');

INSERT INTO public.d (KEY, num)
  VALUES ((
      SELECT
        key::uuid
      FROM
        public.d
      WHERE
        num = 1), 3);

SELECT
  public.pgdms_set_action ('public.d', (
      SELECT
        KEY
      FROM
        d
      WHERE
        num = 3), 'agreed'::pgdms_actiontype, '--');

SELECT
  public.pgdms_set_action ('public.d', (
      SELECT
        KEY
      FROM
        d
      WHERE
        num = 3), 'approved'::pgdms_actiontype, NULL);

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
        key::uuid
      FROM
        public.d
      WHERE
        num = 1), 'a1');

SELECT
  d.num
FROM
  d,
  dup
WHERE
  d.key = dup.d;

SELECT
  d.num
FROM
  d,
  dn
WHERE
  d.key = dn.d;

SELECT
  d.num
FROM
  d,
  dup
WHERE
  dup.d = d.key;

SELECT
  d.num
FROM
  d,
  dn
WHERE
  dn.d = d.key;

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
  KEY = 'document'::pgdms_status;

--Вывод дествий по всем строкам
--Результат с плановой ошибкой из-за времени	
--SELECT pgdms_get_actions(key),pgdms_get_hash(key),pgdms_get_status(key) FROM d;	
--Вывод статуса строк
SELECT
  pgdms_get_status (KEY)
FROM
  d;

--Вывод только действующих документов
SELECT
  num,
  pgdms_get_status (KEY)
FROM
  d
WHERE
  pgdms_is_document (KEY);

--Вывод только  документов на дату
--SELECT num, pgdms_get_status(key) FROM d WHERE pgdms_is_document(key, now()-'20 milliseconds'::interval);
--Вывод записей одного семейства
SELECT
  num,
  pgdms_get_status (KEY)
FROM
  d
WHERE
  pgdms_is_family (KEY, (
      SELECT
        KEY
      FROM
        d
      WHERE
        num = 1));

SELECT
  num,
  pgdms_get_status (KEY)
FROM
  d
WHERE
  pgdms_is_family (KEY, (
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
  pgdms_is_last ('public.d', KEY);

