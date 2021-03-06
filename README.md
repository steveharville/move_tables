# move_tables

PL/SQL package to move tables to new tablespace

Our Supply Chain application creates a lot of tablespaces when it is installed. Then it creates tables in those tablespaces. Over the course of time, we have received updates from the software vendor that create additional tables. Some of these table creation scripts did not specify a tablespace, so the new tables were created in the default tablespace for the schema owner. I wrote this package to move the tables (and indexes) to the correct tablespaces.

I did not consider "alter table" because these databases are in continuous use by the development and testing teams. I happened to see an email on the oracle-l mailing list where Andrew Kerber was working on a similar issue. He posted his script and that is where I got the inspiration to write this package. See : https://www.freelists.org/post/oracle-l/Dbms-metadata-experts,12

I had used dbms_redefinition in the past to redefine tables to use partitions. I had done all that manually and I kept the log files. So I was able to figure out the redefinition function quickly. The part that took more time was the dbms_metadata function to generate the interim table ddl. 

I wanted this package to be easy to read and easy to understand. I used my favorite programming structure, a series of nested if statements that test the outcome of functions. I used error trapping so that the errors could be handled without stopping the procedure. I'm currently running this in our non-prod databases without any issues. Of course you should test it before running it in production.

Complile and run as sys. 

See the example in run_move_tables.sql

Source code: https://github.com/steveharville/move_tables

Blog post: https://steveharville.wordpress.com/2015/04/08/plsql-package-to-move-tables-to-new-tablespace/
