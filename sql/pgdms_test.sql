CREATE EXTENSION pgdms CASCADE;

SELECT hello();


CREATE TABLE public.d
(
    key pgdms_did NOT NULL,
    num integer,
    CONSTRAINT d_pkey PRIMARY KEY (key)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

CREATE SEQUENCE public.dup_key_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

CREATE TABLE public.dup
(
    key integer NOT NULL DEFAULT nextval('dup_key_seq'::regclass),
    d pgdms_didup,
    name text COLLATE pg_catalog."default",
    CONSTRAINT dup_pkey PRIMARY KEY (key),
    CONSTRAINT dup_d_fkey FOREIGN KEY (d)
        REFERENCES public.d (key) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

CREATE SEQUENCE public.dn_key_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

CREATE TABLE public.dn
(
    key integer NOT NULL DEFAULT nextval('dn_key_seq'::regclass),
    d pgdms_didn,
    name text COLLATE pg_catalog."default",
    CONSTRAINT dn_pkey PRIMARY KEY (key),
    CONSTRAINT dn_d_fkey FOREIGN KEY (d)
        REFERENCES public.d (key) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;


INSERT INTO public.d(
	key, num)
	VALUES (null::uuid, 1);
	
INSERT INTO public.d(
	key, num)
	VALUES ((SELECT key::uuid FROM public.d where num = 1), 2);

SELECT public.pgdms_changestatus(
	'public.d', 
	(select key from d where num = 2), 
	'key', 
	'document'::pgdms_status
);


INSERT INTO public.d(
	key, num)
	VALUES ((SELECT key::uuid FROM public.d where num = 1), 3);

SELECT public.pgdms_changestatus(
	'public.d', 
	(select key from d where num = 3), 
	'key', 
	'document'::pgdms_status
);


INSERT INTO public.dup(
	 d, name)
	VALUES ( (SELECT key::uuid FROM public.d where num = 1), 'a1');
	
	
INSERT INTO public.dn(
	 d, name)
	VALUES ( (SELECT key::uuid FROM public.d where num = 1), 'a1');
	

SELECT d.num FROM d,dup WHERE d.key = dup.d;

SELECT d.num FROM d,dn WHERE d.key = dn.d;	

INSERT INTO public.d(
	key, num)
	VALUES ('2604bebd-3369-423c-be17-9e27e50c823b'::uuid, 4);

SELECT count(*) FROM public.d;	

SELECT num FROM public.d WHERE key = 'document'::pgdms_status;	
	
	

