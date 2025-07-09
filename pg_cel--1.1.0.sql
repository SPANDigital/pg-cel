-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pg_cel" to load this file. \quit

-- Function to evaluate CEL expressions with simple data
CREATE OR REPLACE FUNCTION cel_eval(expression text, data text DEFAULT '')
RETURNS text
AS 'MODULE_PATHNAME', 'cel_eval_pg'
LANGUAGE C STRICT IMMUTABLE;

-- Function to evaluate CEL expressions with JSON data
CREATE OR REPLACE FUNCTION cel_eval_json(expression text, json_data text DEFAULT '{}')
RETURNS text
AS 'MODULE_PATHNAME', 'cel_eval_json_pg'
LANGUAGE C STRICT IMMUTABLE;

-- Function to check if a CEL expression compiles correctly
CREATE OR REPLACE FUNCTION cel_compile_check(expression text)
RETURNS text
AS 'MODULE_PATHNAME', 'cel_compile_check_pg'
LANGUAGE C STRICT IMMUTABLE;

-- Function to get cache statistics
CREATE OR REPLACE FUNCTION cel_cache_stats()
RETURNS text
AS 'MODULE_PATHNAME', 'cel_cache_stats_pg'
LANGUAGE C STRICT VOLATILE;

-- Function to clear all caches
CREATE OR REPLACE FUNCTION cel_cache_clear()
RETURNS text
AS 'MODULE_PATHNAME', 'cel_cache_clear_pg'
LANGUAGE C STRICT VOLATILE;

-- Convenience function for common use cases
CREATE OR REPLACE FUNCTION cel_eval_bool(expression text, json_data text DEFAULT '{}')
RETURNS boolean
AS $$
BEGIN
    RETURN (cel_eval_json(expression, json_data))::boolean;
EXCEPTION
    WHEN OTHERS THEN
        RETURN false;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE
SET search_path = pg_catalog, pg_temp;

-- Overloaded version for JSONB input
CREATE OR REPLACE FUNCTION cel_eval_bool(expression text, json_data jsonb)
RETURNS boolean
AS $$
BEGIN
    RETURN (cel_eval_json(expression, json_data::text))::boolean;
EXCEPTION
    WHEN OTHERS THEN
        RETURN false;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE
SET search_path = pg_catalog, pg_temp;

-- Convenience function for numeric results
CREATE OR REPLACE FUNCTION cel_eval_numeric(expression text, json_data text DEFAULT '{}')
RETURNS numeric
AS $$
BEGIN
    RETURN (cel_eval_json(expression, json_data))::numeric;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE
SET search_path = pg_catalog, pg_temp;

-- Overloaded version for JSONB input
CREATE OR REPLACE FUNCTION cel_eval_numeric(expression text, json_data jsonb)
RETURNS numeric
AS $$
BEGIN
    RETURN (cel_eval_json(expression, json_data::text))::numeric;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE
SET search_path = pg_catalog, pg_temp;

-- Convenience function for string results
CREATE OR REPLACE FUNCTION cel_eval_string(expression text, json_data text DEFAULT '{}')
RETURNS text
AS $$
BEGIN
    RETURN cel_eval_json(expression, json_data);
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE
SET search_path = pg_catalog, pg_temp;

-- Overloaded version for JSONB input
CREATE OR REPLACE FUNCTION cel_eval_string(expression text, json_data jsonb)
RETURNS text
AS $$
BEGIN
    RETURN cel_eval_json(expression, json_data::text);
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE
SET search_path = pg_catalog, pg_temp;
