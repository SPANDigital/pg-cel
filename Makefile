EXTENSION = pg_cel

# Extension SQL files (organized by type)
# Installation scripts (base versions)
INSTALL_SCRIPTS = pg_cel--1.4.0.sql pg_cel--1.5.0.sql pg_cel--1.6.0.sql
# Upgrade scripts (version transitions)  
UPGRADE_SCRIPTS = pg_cel--1.4.0--1.5.0.sql pg_cel--1.5.0--1.6.0.sql
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

# BDD Testing targets
bdd-setup:
	@echo "Setting up BDD test environment..."
	@./setup_bdd_tests.sh

bdd-test: bdd-setup
	@echo "Running BDD tests..."
	@cd tests && go test -v -run TestFeatures

bdd-test-pretty:
	@echo "Running BDD tests with pretty format..."
	@cd tests && go test -v -run TestFeatures

bdd-test-junit:
	@echo "Running BDD tests with JUnit output..."
	@cd tests && go test -v -run TestFeatures

bdd-test-coverage:
	@echo "Running BDD tests with coverage..."
	@cd tests && go test -v -coverprofile=../bdd-coverage.out -run TestFeatures

bdd-clean:
	@echo "Cleaning up BDD test artifacts..."
	@dropdb --if-exists test_pgcel 2>/dev/null || true
	@rm -f bdd-results.xml bdd-coverage.out

.PHONY: clean bdd-setup bdd-test bdd-test-pretty bdd-test-junit bdd-test-coverage bdd-clean
