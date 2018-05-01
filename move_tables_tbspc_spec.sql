/*
copyright Steve Harville April 7, 2015
*/
create or replace package mv_tbls_tblspc 
AS
procedure move_tables(
  schemaname varchar2,
  old_tablespace varchar2,
  interim_table_suffix varchar2,
  new_tablespace varchar2,
  new_idx_tspc in varchar2);
function create_interim_table(
  schemaname varchar2,	
  interim_table_ddl varchar2)
  return boolean;
function drop_interim_table(
  schemaname varchar2,
  interim_table_name varchar2)
  return boolean;
function get_interim_ddl(
  schemaname varchar2,	
  table_name varchar2,
  interim_table_name varchar2,
  old_tablespace varchar2,
  new_tablespace varchar2)
  return varchar2; 
function move_idx(
  schemaname varchar2,	
  t_name varchar2,
  new_index_tablespace varchar2)
  return boolean;
function redefine_table(
  schemaname varchar2,	
  table_name varchar2,
  interim_table_name varchar2)
  return boolean;
end mv_tbls_tblspc;

/
