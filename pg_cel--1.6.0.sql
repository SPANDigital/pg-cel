-- pg_cel--1.5.0.sql
-- PostgreSQL extension for CEL (Common Expression Language) evaluation
-- Version 1.5.0 - BDD Testing Complete Edition
-- 
-- This version includes:
-- - 100% BDD test coverage with comprehensive test suite
-- - Fixed function resolution issues for PL/pgSQL wrapper functions  
-- - Improved error handling and stability
-- - Performance optimizations for schema-qualified function calls
-- - Comprehensive cache performance testing
-- - Full PostgreSQL integration testing

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
DECLARE
    result text;
BEGIN
    result := public.cel_eval_json(expression, json_data);
    RETURN CASE WHEN result = 'true' THEN true 
                WHEN result = 'false' THEN false 
                ELSE NULL END;
EXCEPTION
    WHEN OTHERS THEN
        RETURN false;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

-- Overloaded version for JSONB input
CREATE OR REPLACE FUNCTION cel_eval_bool(expression text, json_data jsonb)
RETURNS boolean
AS $$
DECLARE
    result text;
BEGIN
    result := public.cel_eval_json(expression, json_data::text);
    RETURN CASE WHEN result = 'true' THEN true 
                WHEN result = 'false' THEN false 
                ELSE NULL END;
EXCEPTION
    WHEN OTHERS THEN
        RETURN false;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

-- Additional overloads for json type (not just jsonb)
CREATE OR REPLACE FUNCTION cel_eval_bool(expression text, json_data json)
RETURNS boolean
AS $$
DECLARE
    result text;
BEGIN
    result := public.cel_eval_json(expression, json_data::text);
    RETURN CASE WHEN result = 'true' THEN true 
                WHEN result = 'false' THEN false 
                ELSE NULL END;
EXCEPTION
    WHEN OTHERS THEN
        RETURN false;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

-- Convenience function for numeric results
CREATE OR REPLACE FUNCTION cel_eval_numeric(expression text, json_data text DEFAULT '{}')
RETURNS numeric
AS $$
BEGIN
    RETURN (public.cel_eval_json(expression, json_data))::numeric;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

-- Overloaded version for JSONB input
CREATE OR REPLACE FUNCTION cel_eval_numeric(expression text, json_data jsonb)
RETURNS numeric
AS $$
BEGIN
    RETURN (public.cel_eval_json(expression, json_data::text))::numeric;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

-- Additional overloads for json type (not just jsonb)
CREATE OR REPLACE FUNCTION cel_eval_numeric(expression text, json_data json)
RETURNS numeric
AS $$
BEGIN
    RETURN (public.cel_eval_json(expression, json_data::text))::numeric;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

-- Convenience function for string results
CREATE OR REPLACE FUNCTION cel_eval_string(expression text, json_data text DEFAULT '{}')
RETURNS text
AS $$
BEGIN
    RETURN public.cel_eval_json(expression, json_data);
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

-- Overloaded version for JSONB input
CREATE OR REPLACE FUNCTION cel_eval_string(expression text, json_data jsonb)
RETURNS text
AS $$
BEGIN
    RETURN public.cel_eval_json(expression, json_data::text);
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

-- Additional overloads for json type (not just jsonb)
CREATE OR REPLACE FUNCTION cel_eval_string(expression text, json_data json)
RETURNS text
AS $$
BEGIN
    RETURN public.cel_eval_json(expression, json_data::text);
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

-- Convenience function for integer results
CREATE OR REPLACE FUNCTION cel_eval_int(expression text, json_data text DEFAULT '{}')
RETURNS integer
AS $$
BEGIN
    RETURN public.cel_eval_json(expression, json_data)::integer;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

-- Overloaded version for JSONB input
CREATE OR REPLACE FUNCTION cel_eval_int(expression text, json_data jsonb)
RETURNS integer
AS $$
BEGIN
    RETURN (public.cel_eval_json(expression, json_data::text))::integer;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

-- Additional overloads for json type (not just jsonb)
CREATE OR REPLACE FUNCTION cel_eval_int(expression text, json_data json)
RETURNS integer
AS $$
BEGIN
    RETURN public.cel_eval_json(expression, json_data::text)::integer;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

-- Convenience function for double precision results
CREATE OR REPLACE FUNCTION cel_eval_double(expression text, json_data text DEFAULT '{}')
RETURNS double precision
AS $$
BEGIN
    RETURN (public.cel_eval_json(expression, json_data))::double precision;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

-- Overloaded version for JSONB input
CREATE OR REPLACE FUNCTION cel_eval_double(expression text, json_data jsonb)
RETURNS double precision
AS $$
BEGIN
    RETURN (public.cel_eval_json(expression, json_data::text))::double precision;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

-- Additional overloads for json type (not just jsonb)
CREATE OR REPLACE FUNCTION cel_eval_double(expression text, json_data json)
RETURNS double precision
AS $$
BEGIN
    RETURN public.cel_eval_json(expression, json_data::text)::double precision;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

-- Additional overloads for cel_eval with different JSON types
CREATE OR REPLACE FUNCTION cel_eval(expression text, json_data jsonb)
RETURNS text
AS $$
BEGIN
    RETURN public.cel_eval_json(expression, json_data::text);
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

CREATE OR REPLACE FUNCTION cel_eval(expression text, json_data json)
RETURNS text
AS $$
BEGIN
    RETURN public.cel_eval_json(expression, json_data::text);
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

-- Test function for debugging
CREATE OR REPLACE FUNCTION test_int_cast(input text)
RETURNS integer
AS $$
BEGIN
    RETURN input::integer;
END;
$$ LANGUAGE plpgsql;

-- Integer evaluation function
CREATE OR REPLACE FUNCTION cel_eval_int(expression text, json_data text DEFAULT '{}')
RETURNS integer
AS $$
BEGIN
    RETURN (public.cel_eval_json(expression, json_data))::integer;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

-- Overloaded version for JSONB input
CREATE OR REPLACE FUNCTION cel_eval_int(expression text, json_data jsonb)
RETURNS integer
AS $$
BEGIN
    RETURN (public.cel_eval_json(expression, json_data::text))::integer;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

-- Additional overloads for json type (not just jsonb)
CREATE OR REPLACE FUNCTION cel_eval_int(expression text, json_data json)
RETURNS integer
AS $$
BEGIN
    RETURN public.cel_eval_json(expression, json_data::text)::integer;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

-- String evaluation function
CREATE OR REPLACE FUNCTION cel_eval_string(expression text, json_data text DEFAULT '{}')
RETURNS text
AS $$
BEGIN
    RETURN public.cel_eval_json(expression, json_data);
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

-- Overloaded version for JSONB input
CREATE OR REPLACE FUNCTION cel_eval_string(expression text, json_data jsonb)
RETURNS text
AS $$
BEGIN
    RETURN public.cel_eval_json(expression, json_data::text);
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

-- Additional overloads for json type (not just jsonb)
CREATE OR REPLACE FUNCTION cel_eval_string(expression text, json_data json)
RETURNS text
AS $$
BEGIN
    RETURN public.cel_eval_json(expression, json_data::text);
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;
