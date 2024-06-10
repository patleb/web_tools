-- noinspection SqlNoDataSourceInspectionForFile

--
-- Clears the PG Unit functions
--
--
drop function if exists test_run_suite;
drop function if exists test_run_all;
drop function if exists test_run_condition;
drop function if exists test_build_procname;
drop function if exists test_get_procname;
drop function if exists test_terminate;
drop function if exists test_autonomous;
drop function if exists test_dblink_connect;
drop function if exists test_dblink_disconnect;
drop function if exists test_dblink_exec;
drop function if exists test_detect_dblink_schema;
drop function if exists test_assertTrue(message VARCHAR, condition BOOLEAN);
drop function if exists test_assertTrue(condition BOOLEAN);
drop function if exists test_assertNotNull;
drop function if exists test_assertNull;
drop function if exists test_fail;
drop type if exists test_results cascade;
