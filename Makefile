EXTENSION = pg_cel

# Extension SQL files (organized by type)
# Installation scripts (base versions)
INSTALL_SCRIPTS = pg_cel--1.0.6.sql pg_cel--1.0.7.sql pg_cel--1.1.0.sql pg_cel--1.2.0.sql
# Upgrade scripts (version transitions)  
UPGRADE_SCRIPTS = pg_cel--1.0.6--1.0.7.sql pg_cel--1.0.7--1.1.0.sql pg_cel--1.1.0--1.2.0.sql
# All SQL files for PostgreSQL
DATA = $(INSTALL_SCRIPTS) $(UPGRADE_SCRIPTS)

MODULE_big = pg_cel
OBJS = pg_wrapper.o

# Go-specific settings
GOCMD = go
GOBUILD = $(GOCMD) build
GOCLEAN = $(GOCMD) clean

# Platform-specific settings
UNAME_S := $(shell uname -s 2>/dev/null || echo Windows)
ifeq ($(UNAME_S),Linux)
    SHLIB_LINK_EXTRA = pg_cel_go.a
endif
ifeq ($(UNAME_S),Darwin)
    SHLIB_LINK_EXTRA = pg_cel_go.a -lresolv -framework CoreFoundation
endif
ifeq ($(findstring Windows,$(UNAME_S)),Windows)
    SHLIB_LINK_EXTRA = pg_cel_go.a -lws2_32
endif
ifeq ($(OS),Windows_NT)
    SHLIB_LINK_EXTRA = pg_cel_go.a -lws2_32
endif

# Default PostgreSQL config - can be overridden
ifeq ($(UNAME_S),Darwin)
    PG_CONFIG ?= /opt/homebrew/opt/postgresql@16/bin/pg_config
else
    PG_CONFIG ?= pg_config
endif

# PostgreSQL extension build
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

# Append our Go archive and platform-specific libs to PGXS-provided SHLIB_LINK
SHLIB_LINK += $(SHLIB_LINK_EXTRA)

# Build Go archive first
pg_wrapper.o: pg_cel_go.a

$(MODULE_big)$(DLSUFFIX): pg_cel_go.a

pg_cel_go.a: main.go
	$(GOBUILD) -buildmode=c-archive -o pg_cel_go.a main.go

clean:
	$(GOCLEAN)
ifeq ($(findstring Windows,$(UNAME_S)),Windows)
	del /f pg_cel_go.a pg_cel_go.h pg_wrapper.o $(MODULE_big)$(DLSUFFIX) 2>nul || true
else
	rm -f pg_cel_go.a pg_cel_go.h pg_wrapper.o $(MODULE_big)$(DLSUFFIX)
endif

.PHONY: clean
