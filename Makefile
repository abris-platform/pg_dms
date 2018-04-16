EXTENSION = pgdms
DATA = pgdms--0.0.1.sql
REGRESS = pgdms_test dvd
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
