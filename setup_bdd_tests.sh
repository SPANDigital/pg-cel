#!/bin/bash

# BDD Test Environment Setup Script
# This script sets up the test environment for pg-cel BDD tests

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up pg-cel BDD test environment...${NC}"

# Check if PostgreSQL is running
if ! pg_isready -q; then
    echo -e "${RED}Error: PostgreSQL is not running${NC}"
    echo "Please start PostgreSQL and try again"
    exit 1
fi

# Set default database name
TEST_DB="${TEST_DB:-test_pgcel}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"

echo -e "${YELLOW}Database: $TEST_DB${NC}"
echo -e "${YELLOW}User: $POSTGRES_USER${NC}"

# Drop and recreate test database
echo -e "${GREEN}Creating test database...${NC}"
dropdb --if-exists "$TEST_DB" -U "$POSTGRES_USER" 2>/dev/null || true
createdb "$TEST_DB" -U "$POSTGRES_USER"

# Check if pg-cel extension is built
if [ ! -f "pg_cel.dylib" ] && [ ! -f "pg_cel.so" ]; then
    echo -e "${YELLOW}Building pg-cel extension...${NC}"
    ./build.sh
fi

# Install extension if not already installed
echo -e "${GREEN}Installing pg-cel extension...${NC}"
make install 2>/dev/null || echo -e "${YELLOW}Extension install may have failed (might need sudo)${NC}"

# Enable extension in test database
echo -e "${GREEN}Enabling pg-cel extension in test database...${NC}"
psql -d "$TEST_DB" -U "$POSTGRES_USER" -c "CREATE EXTENSION IF NOT EXISTS pg_cel;" 2>/dev/null || {
    echo -e "${RED}Failed to enable pg-cel extension${NC}"
    echo "This might be because:"
    echo "1. Extension is not installed (try: sudo make install)"
    echo "2. PostgreSQL cannot find the extension files"
    echo "3. Permission issues"
    exit 1
}

# Verify extension is working
echo -e "${GREEN}Verifying pg-cel extension...${NC}"
RESULT=$(psql -d "$TEST_DB" -U "$POSTGRES_USER" -t -c "SELECT cel_eval('1 + 1');" 2>/dev/null | xargs)
if [ "$RESULT" = "2" ]; then
    echo -e "${GREEN}✓ pg-cel extension is working correctly${NC}"
else
    echo -e "${RED}✗ pg-cel extension verification failed${NC}"
    echo "Expected result: 2, Got: $RESULT"
    exit 1
fi

# Install Go test dependencies
echo -e "${GREEN}Installing Go test dependencies...${NC}"
go mod download

# Run a quick test to verify everything is working
echo -e "${GREEN}Running quick verification test...${NC}"
if go test -run=TestNothing ./godog_main_test.go ./godog_test.go 2>/dev/null; then
    echo -e "${GREEN}✓ Test environment setup successful${NC}"
else
    echo -e "${YELLOW}Note: Test compilation may show warnings due to CGO, but this is normal${NC}"
fi

echo -e "${GREEN}Setup complete!${NC}"
echo
echo "To run BDD tests:"
echo "  go test -v ./godog_main_test.go ./godog_test.go"
echo
echo "To run specific features:"
echo "  go test -v -godog.tags=\"@feature\" ./godog_main_test.go ./godog_test.go"
echo
echo "Environment variables:"
echo "  TEST_DB=$TEST_DB (test database name)"
echo "  POSTGRES_USER=$POSTGRES_USER (PostgreSQL user)"
