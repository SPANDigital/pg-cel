#include "postgres.h"
#include "fmgr.h"
#include "utils/builtins.h"
#include "utils/varlena.h"
#include "utils/guc.h"
#include "pg_cel_go.h"

PG_MODULE_MAGIC;

// Configuration variables
static int program_cache_size_mb = 128;   // Default 128MB (halved from 256MB)
static int json_cache_size_mb = 64;       // Default 64MB (halved from 128MB)

// Forward declarations for Go functions (these are the actual Go function names)
extern char* pg_cel_eval(char* expression, char* data);
extern char* pg_cel_eval_json(char* expression, char* json_data);
extern char* pg_cel_compile_check(char* expression);
extern void pg_init_caches(GoInt program_cache_mb, GoInt json_cache_mb);
extern char* pg_cel_cache_stats(void);
extern char* pg_cel_cache_clear(void);

// Module initialization function
void _PG_init(void);

void
_PG_init(void)
{
    // Define custom GUC parameters
    DefineCustomIntVariable("pg_cel.program_cache_size_mb",
                           "Size of CEL program cache in MB",
                           "Sets the maximum size of the CEL program compilation cache in megabytes.",
                           &program_cache_size_mb,
                           128,            // default value (halved from 256MB)
                           64,             // min value (64MB)
                           8192,           // max value (8GB)
                           PGC_SUSET,      // can be set by superuser
                           0,              // flags
                           NULL,           // check_hook
                           NULL,           // assign_hook
                           NULL);          // show_hook

    DefineCustomIntVariable("pg_cel.json_cache_size_mb",
                           "Size of JSON cache in MB",
                           "Sets the maximum size of the JSON parsing cache in megabytes.",
                           &json_cache_size_mb,
                           64,             // default value (halved from 128MB)
                           32,             // min value (32MB)
                           4096,           // max value (4GB)
                           PGC_SUSET,      // can be set by superuser
                           0,              // flags
                           NULL,           // check_hook
                           NULL,           // assign_hook
                           NULL);          // show_hook

    // Initialize Go caches with configured values
    pg_init_caches((GoInt)program_cache_size_mb, (GoInt)json_cache_size_mb);
}

// PostgreSQL function wrappers (using different names to avoid conflicts)
PG_FUNCTION_INFO_V1(cel_eval_pg);
PG_FUNCTION_INFO_V1(cel_eval_json_pg);
PG_FUNCTION_INFO_V1(cel_compile_check_pg);
PG_FUNCTION_INFO_V1(cel_cache_stats_pg);
PG_FUNCTION_INFO_V1(cel_cache_clear_pg);

Datum
cel_eval_pg(PG_FUNCTION_ARGS)
{
    text *expression = PG_GETARG_TEXT_PP(0);
    text *data = PG_GETARG_TEXT_PP(1);

    char *expr_str = text_to_cstring(expression);
    char *data_str = text_to_cstring(data);

    // Call the Go function
    char *result = pg_cel_eval(expr_str, data_str);

    PG_RETURN_TEXT_P(cstring_to_text(result));
}

Datum
cel_eval_json_pg(PG_FUNCTION_ARGS)
{
    text *expression = PG_GETARG_TEXT_PP(0);
    text *json_data = PG_GETARG_TEXT_PP(1);

    char *expr_str = text_to_cstring(expression);
    char *json_str = text_to_cstring(json_data);

    // Call the Go function
    char *result = pg_cel_eval_json(expr_str, json_str);

    PG_RETURN_TEXT_P(cstring_to_text(result));
}

Datum
cel_compile_check_pg(PG_FUNCTION_ARGS)
{
    text *expression = PG_GETARG_TEXT_PP(0);

    char *expr_str = text_to_cstring(expression);

    // Call the Go function
    char *result = pg_cel_compile_check(expr_str);

    PG_RETURN_TEXT_P(cstring_to_text(result));
}

Datum
cel_cache_stats_pg(PG_FUNCTION_ARGS)
{
    // Call the Go function
    char *result = pg_cel_cache_stats();

    PG_RETURN_TEXT_P(cstring_to_text(result));
}

Datum
cel_cache_clear_pg(PG_FUNCTION_ARGS)
{
    // Call the Go function
    char *result = pg_cel_cache_clear();

    PG_RETURN_TEXT_P(cstring_to_text(result));
}
