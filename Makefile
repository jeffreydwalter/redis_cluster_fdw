##########################################################################
#
#                foreign-data wrapper for Redis
#
# Copyright (c) 2011,2013 PostgreSQL Global Development Group
#
# This software is released under the PostgreSQL Licence
#
# Authors: Dave Page <dpage@pgadmin.org>
#          Andrew Dunstan <andrew@dunslane.net>
#          Jeffrey Walter <jeffreydwalter@gmail.com>
#
# IDENTIFICATION
#                 redis_cluster_fdw/Makefile
# 
##########################################################################

MODULE_big = redis_cluster_fdw
OBJS = redis_cluster_fdw.o

EXTENSION = redis_cluster_fdw
DATA = redis_cluster_fdw--1.0.sql

REGRESS = redis_cluster_fdw
REGRESS_OPTS = --inputdir=test --outputdir=test \
      --load-extension=hstore \
	  --load-extension=$(EXTENSION)

EXTRA_CLEAN = sql/redis_cluster_fdw.sql expected/redis_cluster_fdw.out

SHLIB_LINK += -lhiredis_cluster
SHLIB_LINK += -lhiredis_ssl
SHLIB_LINK += -lhiredis

USE_PGXS = 1

ifeq ($(USE_PGXS),1)
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
else
subdir = contrib/redis_cluster_fdw
top_builddir = ../..
include $(top_builddir)/src/Makefile.global
include $(top_srcdir)/contrib/contrib-global.mk
endif

# we put all the tests in a test subdir, but pgxs expects us not to, darn it
override pg_regress_clean_files = test/results/ test/regression.diffs test/regression.out tmp_check/ log/
