-- noinspection SqlNoDataSourceInspectionForFile

--
-- Clears the PG Unit functions
--
--
drop function if exists test_run_suite(TEXT);
drop function if exists test_run_all();
drop function if exists test_run_condition(proc_name text);
drop function if exists test_build_procname(parts text[], p_from integer, p_to integer);
drop function if exists test_get_procname(test_case_name text, expected_name_count integer, result_prefix text);
drop function if exists test_terminate(db VARCHAR);
drop function if exists test_autonomous(p_statement VARCHAR);
drop function if exists test_dblink_connect(text, text);
drop function if exists test_dblink_disconnect(text);
drop function if exists test_dblink_exec(text, text);
drop function if exists test_detect_dblink_schema();
drop function if exists test_assertTrue(message VARCHAR, condition BOOLEAN);
drop function if exists test_assertTrue(condition BOOLEAN);
drop function if exists test_assertNotNull(VARCHAR, ANYELEMENT);
drop function if exists test_assertNull(VARCHAR, ANYELEMENT);
drop function if exists test_fail(VARCHAR);
drop type if exists test_results cascade;
