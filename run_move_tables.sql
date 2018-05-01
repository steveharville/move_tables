-- copyright 2015 Steve Harville
drop table  steveharville.wrong_tsp;
create table steveharville.wrong_tsp as (select * from dba_objects) ;
alter table steveharville.wrong_tsp add primary key (OBJECT_ID);
create index steveharville.wrong_idx on steveharville.wrong_tsp (created);
select count(*) from  steveharville.wrong_tsp;
select tablespace_name from dba_tables where table_name = 'WRONG_TSP';
select tablespace_name from dba_indexes where index_name = 'WRONG_IDX';
drop table  steveharville.wrong_tsp2;
create table steveharville.wrong_tsp2 as (select * from dba_objects) ;
alter table steveharville.wrong_tsp2 add primary key (OBJECT_ID);
create index steveharville.wrong_idx2 on steveharville.wrong_tsp2 (created);
select count(*) from  steveharville.wrong_tsp2;
select tablespace_name from dba_tables where table_name like 'WRONG_TSP%';
select tablespace_name from dba_indexes where index_name like 'WRONG_IDX%';
@move_tables_tbspc_spec.sql
@move_tables_tbspc_body.sql
exec mv_tbls_tblspc.move_tables('STEVEHARVILLE','USERS','I','STEVE','STEVE_IDX')
select tablespace_name from dba_tables where table_name like 'WRONG_TSP%';
select tablespace_name from dba_indexes where index_name like 'WRONG_IDX%';
select object_name, base_table_name, ddl_txt from DBA_REDEFINITION_ERRORS;
