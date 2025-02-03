--------------------------------------------------------------------------------
--------------------PL_CPL_SQL--------------------------------------------------

-- handler
CREATE FUNCTION pl_cpl_sql_call_handler() RETURNS language_handler AS '$libdir/pl_cpl_sql_ext' LANGUAGE C;

-- inline
CREATE FUNCTION pl_cpl_sql_inline_handler(oid internal) RETURNS void AS '$libdir/pl_cpl_sql_ext', 'pl_cpl_sql_inline_handler' LANGUAGE C;

-- validator
CREATE FUNCTION pl_cpl_sql_validator(oid_ oid) RETURNS void AS '$libdir/pl_cpl_sql_ext', 'pl_cpl_sql_validator' LANGUAGE C;

CREATE TRUSTED LANGUAGE pl_cpl_sql HANDLER pl_cpl_sql_call_handler INLINE pl_cpl_sql_inline_handler validator pl_cpl_sql_validator;

COMMENT ON LANGUAGE pl_cpl_sql IS 'PL/cPLSQL procedural language';

