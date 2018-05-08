CREATE EXTENSION pg_dms CASCADE;

--
--  Создание таблицы справочник
--
CREATE TABLE public.directory (
  KEY pg_dms_id NOT NULL DEFAULT uuid_generate_v4(),
  num integer,
  CONSTRAINT d_pkey PRIMARY KEY (KEY)
)
WITH (OIDS = FALSE) TABLESPACE pg_default;
--
--  Вставка значений по умочанию
--

-- Закоментировать - будут вставлены случайные ключи
--INSERT INTO public.directory (num) VALUES (1);
--INSERT INTO public.directory (num)  VALUES (2);
--
--  Вставка заначений в виде pg_dms_id
--
INSERT INTO public.directory (KEY, num)
  VALUES (('73a0d05a-d681-4bb3-9e31-9f52ee938ad2,eec4a453-4a90-49e9-8044-b6b51311ad5a')::pg_dms_id, 3);
--
--  Вставка заначений в виде строки
--
INSERT INTO public.directory (KEY, num)
  VALUES ('3ea227be-9932-4fb1-b47a-84c1851b419a,7cea1a82-213d-41aa-97f2-80138b538ca6', 4);
INSERT INTO public.directory (KEY, num)
  VALUES ('ae060476-a0c1-4ec1-993f-f71ba3882796,29a1e5f1-33f8-477b-958d-3868edfbbfcf', 5);
INSERT INTO public.directory (KEY, num)
  VALUES ('ae060476-a0c1-4ec1-993f-f71ba3882796,381adf5e-5ec2-4855-a25d-b22ef99fcfa8', 6);
INSERT INTO public.directory (KEY, num)
  VALUES ('ae060476-a0c1-4ec1-993f-f71ba3882796,cc8a3b5b-9899-4038-ac01-67a6b0450eff', 8);
--
--  Создание новой версии строки
--
INSERT INTO public.directory (KEY, num)
  VALUES (pg_dms_createversion(('ae060476-a0c1-4ec1-993f-f71ba3882796,cc8a3b5b-9899-4038-ac01-67a6b0450eff')::pg_dms_id,
          '6e108955-7aff-4a9c-871c-a41fb8006594'::uuid), 7);
--
--  Просмотр результата создания таблицы
--
SELECT * FROM directory order by key;
--
--  Поиск записей по различным условиям
--
SELECT * FROM directory WHERE key > '73a0d05a-d681-4bb3-9e31-9f52ee938ad2,eec4a453-4a90-49e9-8044-b6b51311ad5a';
SELECT * FROM directory WHERE key >= '73a0d05a-d681-4bb3-9e31-9f52ee938ad2,eec4a453-4a90-49e9-8044-b6b51311ad5a';
SELECT * FROM directory WHERE key = '73a0d05a-d681-4bb3-9e31-9f52ee938ad2,eec4a453-4a90-49e9-8044-b6b51311ad5a';
SELECT * FROM directory WHERE key < '73a0d05a-d681-4bb3-9e31-9f52ee938ad2,eec4a453-4a90-49e9-8044-b6b51311ad5a';
SELECT * FROM directory WHERE key <= '73a0d05a-d681-4bb3-9e31-9f52ee938ad2,eec4a453-4a90-49e9-8044-b6b51311ad5a';
--
--  Добавление действия со строкой
--
UPDATE directory SET key=pg_dms_setaction(key, 100, (SELECT oid FROM pg_class WHERE relname = 'directory'), '73a0d05a-d681-4bb3-9e31-9f52ee938ad2'::uuid) WHERE num = 3;
UPDATE directory SET key=pg_dms_setaction(key, 200, (SELECT oid FROM pg_class WHERE relname = 'directory'), '73a0d05a-d681-4bb3-9e31-9f52ee938ad2'::uuid) WHERE num = 3;
--
--  Получение статуса строки
--
SELECT pg_dms_getstatus(key), num FROM directory;

--Закоментировать - возвращается текущая дата
--SELECT pg_dms_getaction(key), num FROM directory;
--
--  Просмот действий со строкой в виде таблицы
--

--Закоментировать - возвращается текущая дата
-- SELECT a.name, au.rolname, "date", c.relname, reason_key FROM unnest((SELECT pg_dms_getaction(key) FROM directory WHERE num = 3) ) AS t
-- LEFT JOIN action_list a ON t.type = a.key 
-- LEFT JOIN pg_catalog.pg_authid au ON t.user = au.oid
-- LEFT JOIN pg_catalog.pg_class c ON t.reason = c.oid;
--
--  Поиск в таблице по значению uuid
--
SELECT * FROM directory WHERE  'ae060476-a0c1-4ec1-993f-f71ba3882796'::uuid = key;
SELECT * FROM directory WHERE  'ae060476-a0c1-4ec1-993f-f71ba3882796'::uuid < key;
SELECT * FROM directory WHERE  'ae060476-a0c1-4ec1-993f-f71ba3882796'::uuid <= key;
SELECT * FROM directory WHERE  'ae060476-a0c1-4ec1-993f-f71ba3882796'::uuid > key;
SELECT * FROM directory WHERE  'ae060476-a0c1-4ec1-993f-f71ba3882796'::uuid >= key;

SELECT * FROM directory WHERE  key = 'ae060476-a0c1-4ec1-993f-f71ba3882796'::uuid;
SELECT * FROM directory WHERE  key < 'ae060476-a0c1-4ec1-993f-f71ba3882796'::uuid;
SELECT * FROM directory WHERE  key <= 'ae060476-a0c1-4ec1-993f-f71ba3882796'::uuid;
SELECT * FROM directory WHERE  key > 'ae060476-a0c1-4ec1-993f-f71ba3882796'::uuid;
SELECT * FROM directory WHERE  key >= 'ae060476-a0c1-4ec1-993f-f71ba3882796'::uuid;
--
--  Создание таблицы в которой есть ссылка на семейство записей в таблице справочника
--
CREATE TABLE public.family (
  KEY integer NOT NULL,
  directory_key pg_dms_family,
  name text,
  CONSTRAINT family_pkey PRIMARY KEY (KEY),
  CONSTRAINT family_directory_fkey FOREIGN KEY (directory_key) REFERENCES public.directory (KEY)
)
  WITH (OIDS = FALSE) TABLESPACE pg_default;
--
--  Добавление записи в таблицу со ссылкий на справочник
--
INSERT INTO public.family (key, directory_key, name) VALUES (1, 'ae060476-a0c1-4ec1-993f-f71ba3882796','a1');
--
--  Просмотр результата вставки
--
SELECT * FROM public.family LEFT JOIN  public.directory ON family.directory_key = directory.key;
--
--  Создание таблицы в которой есть ссылка на записи в таблице справочника
--
CREATE TABLE public.ref (
  KEY integer NOT NULL,
  directory_key pg_dms_ref,
  name text,
  CONSTRAINT ref_pkey PRIMARY KEY (KEY),
  CONSTRAINT ref_directory_fkey FOREIGN KEY (directory_key) REFERENCES public.directory (KEY)
)
  WITH (OIDS = FALSE) TABLESPACE pg_default;
--
--  Добавление записи в таблицу со ссылкий на справочник
--
INSERT INTO public.ref (key, directory_key, name) VALUES (1, 'ae060476-a0c1-4ec1-993f-f71ba3882796,29a1e5f1-33f8-477b-958d-3868edfbbfcf','a1');
--
--  Просмотр результата вставки
--
SELECT * FROM public.ref LEFT JOIN  public.directory ON ref.directory_key = directory.key;

/*
Не создается CONSTRAINT 
ERROR:  foreign key constraint "test_uuid_directory_fkey" cannot be implemented
DETAIL:  Key columns "directory_key" and "key" are of incompatible types: uuid and pg_dms_id.

CREATE TABLE public.test_uuid (
  KEY integer NOT NULL,
  directory_key uuid,
  name text,
  CONSTRAINT test_uuid_pkey PRIMARY KEY (KEY),
  CONSTRAINT test_uuid_directory_fkey FOREIGN KEY (directory_key) REFERENCES public.directory (KEY)
)
  WITH (OIDS = FALSE) TABLESPACE pg_default;
--
--  Добавление записи в таблицу со ссылкий на справочник
--
INSERT INTO public.ref (key, directory_key, name) VALUES (1, 'ae060476-a0c1-4ec1-993f-f71ba3882796','a1');
--
--  Просмотр результата вставки
--
SELECT * FROM public.ref LEFT JOIN  public.directory ON ref.directory_key = directory.key;
*/
--
--  Расчет JSON
--
-- Закомментировано, потому что возвращается текущее время
--select pg_dms_getjson(directory, key) from directory;
--
--  Расчет хеш строк
--
--Закоментировать - возвращается текущая дата
-- select pg_dms_gethash(directory, key),num from directory;
--
--  Расчет строк для хеш 
--
--Закоментировать - возвращается текущая дата
-- select pg_dms_getstringforhash(directory, key) from directory;
--
--  Добавление хеша в ключ 
--
UPDATE directory SET key = pg_dms_setHash(directory, key) WHERE num = 3;

--Закоментировать - возвращается текущая дата
-- SELECT a.name, au.rolname, "date", c.relname, reason_key FROM unnest((SELECT pg_dms_getaction(key) FROM directory WHERE num = 3) ) AS t
-- LEFT JOIN action_list a ON t.type = a.key 
-- LEFT JOIN pg_catalog.pg_authid au ON t.user = au.oid
-- LEFT JOIN pg_catalog.pg_class c ON t.reason = c.oid;
--
--  Проверяет хеш 
--
--Закоментировать - возвращается текущая дата
-- select pg_dms_checkhash(directory, key), num from directory;
--
--  Добавление записи из json 
--
SELECT pf_dms_insert_from_json('{"schema": "public", "table": "directory", "key": "f723f29c-5dd3-4a45-a436-dc5076877c11,581c1426-e76a-4654-a23b-b948cd96453b", "columns": [{"name": "key", "type": "pg_dms_id", "value": "f723f29c-5dd3-4a45-a436-dc5076877c11,581c1426-e76a-4654-a23b-b948cd96453b"}, {"name": "num", "type": "int4", "value": "45"}], "actions": [{"type": 0, "user": 10, "date": "2018-04-29 02:47:54.911326-07"}]}'::json);
SELECT * FROM directory;
--
--  Добавление записи в реестр 
--
--SELECT pf_dms_insert_to_register('public', 'directory', 'key', key) FROM public.directory WHERE num = 3;

SELECT pf_dms_insert_to_register('public', 'directory', 'key', key) FROM public.directory WHERE num < 5;

SELECT count(*) FROM public.register;
SELECT a.name, au.rolname, c.relname FROM unnest((SELECT pg_dms_getaction(key) FROM directory WHERE num = 3) ) AS t
  LEFT JOIN action_list a ON t.type = a.key 
  LEFT JOIN pg_catalog.pg_authid au ON t.user = au.oid
  LEFT JOIN pg_catalog.pg_class c ON t.reason = c.oid;

SELECT get_status_rigister(key), num FROM  directory; 




SELECT pf_dms_save_file(pf_dms_create_file(),  '192.168.100.128');

SELECT * FROM public.global_register;

SELECT response_file, local_db from public.global_register_file WHERE status = 0;




UPDATE public.register SET status=1, num_register='e0a0c1db-a4a0-4991-bdb4-f1f8ccf3df08', ex_inserted=now();
SELECT count(*) FROM public.register;
SELECT a.name, au.rolname, c.relname FROM unnest((SELECT pg_dms_getaction(key) FROM directory WHERE num = 3) ) AS t
  LEFT JOIN action_list a ON t.type = a.key 
  LEFT JOIN pg_catalog.pg_authid au ON t.user = au.oid
  LEFT JOIN pg_catalog.pg_class c ON t.reason = c.oid;

SELECT get_status_rigister(key), num FROM  directory; 


