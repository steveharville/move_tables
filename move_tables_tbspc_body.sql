/*
Steve Harville April 7, 2015
*/
create or replace package body mv_tbls_tblspc 
AS
procedure move_tables(
  schemaname in varchar2,
  old_tablespace in varchar2,
  interim_table_suffix in varchar2,
  new_tablespace in varchar2,
  new_idx_tspc in varchar2)
as
  interim_ddl_sql varchar(32000);
  interim_tablename varchar(70);
begin
 	dbms_output.put_line('Schema name =' || schemaname);
  	dbms_output.put_line('tablespace =' || old_tablespace);
	for ctable in  ( select table_name 
     			from dba_tables 
     			where tablespace_name = old_tablespace
     			and owner = schemaname)
	loop
    	dbms_output.put_line('----------------------------------------------------------------------');
    	dbms_output.put_line('table name =' || ctable.table_name);
		interim_tablename:=ctable.table_name || interim_table_suffix;
		dbms_output.put_line('Interim table =' || interim_tablename);
		interim_ddl_sql:=get_interim_ddl(schemaname,ctable.table_name,interim_tablename, old_tablespace,new_tablespace);
		dbms_output.put_line('Interim DDL=' || interim_ddl_sql);

		if create_interim_table(schemaname,interim_ddl_sql)
		then
			dbms_output.put_line('Interim table created for ' || ctable.table_name || ' as ' || interim_tablename);
			if move_idx(schemaname,ctable.table_name,new_idx_tspc)
			then
				dbms_output.put_line('Indexes for ' ||  ctable.table_name || ' moved to tablespace ' || new_idx_tspc);
			else
				dbms_output.put_line('Move indexes for ' || ctable.table_name || ' to ' || new_idx_tspc || ' failed ' );
			end if;
			if redefine_table(schemaname,ctable.table_name,interim_tablename)
			then
				dbms_output.put_line('Table ' || ctable.table_name || ' sucessfully redefined to use tablespace ' || new_tablespace);
			else
				dbms_output.put_line('Move ' || ctable.table_name || ' to ' || new_tablespace || ' failed ' );
			end if;
			if drop_interim_table(schemaname,interim_tablename)
			then
				dbms_output.put_line('Dropped interim table '  || interim_tablename);
			else
				dbms_output.put_line('Interim table ' || interim_tablename || ' could not be dropped ' );
			end if;	
		else
			dbms_output.put_line('Create interim table failed ' || interim_tablename);
		end if;	
	end loop;
end  move_tables;

function redefine_table(
  schemaname varchar2,
  table_name varchar2,
  interim_table_name varchar2)
  return boolean
as
num_errors pls_integer;
begin
	dbms_redefinition.can_redef_table(schemaname,table_name, dbms_redefinition.cons_use_rowid) ; 
	dbms_redefinition.start_redef_table(schemaname,table_name,interim_table_name, NULL,dbms_redefinition.cons_use_rowid ) ;
	dbms_redefinition.COPY_TABLE_DEPENDENTS(schemaname,table_name,interim_table_name,DBMS_REDEFINITION.CONS_ORIG_PARAMS, TRUE, TRUE, TRUE, TRUE,num_errors) ;
	dbms_output.put_line('dependent errors: ' || num_errors);
	dbms_redefinition.SYNC_INTERIM_TABLE(schemaname,table_name,interim_table_name) ;
	dbms_redefinition.FINISH_REDEF_TABLE(schemaname,table_name,interim_table_name) ; 
	return true;
	exception
	when others then
         dbms_output.put_line('An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
         dbms_output.put_line('Aborting redefinition');
 	       dbms_redefinition.abort_redef_table(schemaname,table_name,interim_table_name) ;
         return FALSE;
end redefine_table;

function create_interim_table(
  schemaname varchar2,	
  interim_table_ddl varchar2)
  return boolean
as
begin
	execute immediate interim_table_ddl ;
	return true;
	exception
	when others then
         dbms_output.put_line('An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
         return FALSE;
end create_interim_table;

function drop_interim_table(
  schemaname varchar2,
  interim_table_name varchar2)
  return boolean
as
sql_txt varchar(300);
begin
	sql_txt := 'drop table ' || schemaname || '.' || interim_table_name  ;
	execute immediate sql_txt ;
	return true;
	exception
	when others then
         dbms_output.put_line('An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
         return false; 
end drop_interim_table;

function get_interim_ddl(
  schemaname varchar2,	
  table_name varchar2,
  interim_table_name varchar2,
  old_tablespace varchar2,
  new_tablespace varchar2)
  return varchar2
as
int_ddl varchar2(32000);
xml_handle number;
transform_handle number;
begin
  xml_handle := dbms_metadata.open('TABLE');
  transform_handle := dbms_metadata.add_transform(xml_handle,'MODIFY');
  dbms_metadata.set_remap_param(transform_handle,'REMAP_TABLESPACE',old_tablespace,new_tablespace);
  transform_handle := dbms_metadata.add_transform(xml_handle,'DDL');
  dbms_metadata.set_filter(xml_handle,'SCHEMA',schemaname);
  dbms_metadata.set_filter(xml_handle,'NAME',table_name);
  dbms_metadata.set_transform_param(transform_handle,'CONSTRAINTS',FALSE);
  dbms_metadata.set_transform_param(transform_handle,'REF_CONSTRAINTS',FALSE);
  int_ddl := dbms_metadata.fetch_clob(xml_handle);
  int_ddl := replace(int_ddl,'."' || table_name,'."' || interim_table_name);
  return int_ddl;
	exception
	when others then
         dbms_output.put_line('An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
         return 'ERROR';
end get_interim_ddl;

function move_idx(
  schemaname varchar2,	
  t_name varchar2,
  new_index_tablespace varchar2)
  return boolean
as
 cursor index_list is (select index_name from dba_indexes where table_name=t_name and owner=schemaname);
 sql_txt varchar2(300);
begin
	for idx in index_list 
    	loop 
    		sql_txt:=( 
  		   'alter index ' 
			  || schemaname
			  || '.'
			  || idx.index_name 
			  || ' rebuild online parallel tablespace '
			  || new_index_tablespace
			 );
		   dbms_output.put_line(sql_txt);
		   execute immediate  sql_txt ;
    end loop;
	return TRUE;
	exception
	when others then
       dbms_output.put_line('An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
       return false; 
end move_idx;
end mv_tbls_tblspc;
/

show errors

