-- If you want to add ASCII Art: https://asciiartgen.now.sh/?style=standard
-- *** DO NOT MODIFY: HEADER SECTION ***
clear screen

whenever sqlerror exit sql.sqlcode

prompt loading environment variables
@load_env_vars.sql


-- define - Sets the character used to prefix substitution variables
-- Note: if you change this you need to modify every reference of it in this file and any referring files
-- set define '&'
-- verify off prevents the old/new substitution message
set verify off
-- feedback - Displays the number of records returned by a script ON=1
set feedback on
-- timing - Displays the time that commands take to complete
set timing on
-- display dbms_output messages
set serveroutput on
-- disables blank lines in code
set sqlblanklines off;


-- Log output of release
define logname = '' -- Name of the log file

set termout on
column my_logname new_val logname
select 'release_log_'||sys_context( 'userenv', 'service_name' )|| '_' || to_char(sysdate, 'YYYY-MM-DD_HH24-MI-SS')||'.log' my_logname from dual;
-- good to clear column names when done with them
column my_logname clear
set termout on
spool &logname
prompt Log File: &logname



prompt check DB user is expected user
declare
begin
  if user != '&env_schema_name' or '&env_schema_name' is null then
    raise_application_error(-20001, 'Must be run as &env_schema_name');
  end if;
end;
/

-- Disable APEX apps
@../scripts/apex_disable.sql &env_apex_app_ids


-- *** END: HEADER SECTION ***


-- *** Release specific tasks ***

@code/_run_code.sql

-- *** DO NOT MODIFY BELOW ***


-- Views and packages will be automatically referenced in the files below
-- Can generate these files from the build script
-- Search for "list_all_files"
@all_views.sql
@all_packages.sql


prompt Invalid objects
select object_name, object_type
from user_objects
where status != 'VALID'
order by object_name
;


-- *** DATA ****


-- Autogenerated triggers
-- If you have code to automatically generate triggers this is a good place to run in.
-- An example of what it might look like:

-- declare
-- begin
--   pkg_util.gen_triggers()
-- end;
-- /


-- Load any re-runnable data scripts
-- ex: @../data/data_my_table.sql


-- This needs to be in place after trigger generation as some triggers follow the generated triggers above
prompt recompile invalid schema objects
begin
 dbms_utility.compile_schema(schema => user, compile_all => false);
end;
/

-- *** APEX ***
-- Install all apex applications
@all_apex.sql


-- Control Build Options (optional)
-- In some cases you may want to enable / disable various build options for an application depending on the environment
-- An example is provided below on how to enabled a build option
PROMPT *** APEX Build option ***

-- set serveroutput on size unlimited;
-- declare
--   c_app_id constant apex_applications.application_id%type := CHANGEME_APPLICATION_ID;
--   c_username constant varchar2(30) := user;

--   l_build_option_id apex_application_build_options.build_option_id%type;
-- begin
--   if pkg_environment.is_dev() then
--     select build_option_id
--     into l_build_option_id
--     from apex_application_build_options
--     where 1=1
--       and application_id = c_app_id
--       and build_option_name='DEV_ONLY';

--     -- Session is already active ahead
--     apex_session.create_session (
--       p_app_id => c_app_id,
--       p_page_id => 1,
--       p_username => c_username );

--     apex_util.set_build_option_status(
--       p_application_id => c_app_id,
--       p_id => l_build_option_id,
--       p_build_status=>'INCLUDE');
--   end if;

-- end;
-- /

-- commit;


spool off
exit