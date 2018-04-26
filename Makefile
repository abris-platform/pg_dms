EXTENSION = pg_dms
DATA = pg_dms--0.0.1.sql
REGRESS = pg_dms_test 
MODULE_big = pg_dms
OBJS = pg_dms.o pg_dms_id.o pg_dms_family.o  
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
