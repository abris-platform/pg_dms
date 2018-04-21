EXTENSION = pg_dms
DATA = pg_dms--0.0.1.sql
REGRESS = pg_dms_test dvd
MODULES = pg_dms
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
