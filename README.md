# Foreign Key Check - PL/pgSQL script
Check all foreign keys in a PostgreSQL database for logical integrity.

Foreign key integrity is vital for your referential integrity and your data qualtiy. 

# Use Case
If you create a foreign key on a table in PostgreSQL it checks if the affected columns fit the foreign key condition. PostgreSQL will make sure that the integrity of the foreign key is valid when rows on the respective tables are modified. You can trust the integritry of the foreign key.

However, if you face corruption in your database you may only solve the problem by allowing data loss. This is the case if you have to zero out the corrupted data pages with the 'zero_damaged_pages' developer option, see https://www.postgresql.org/docs/current/runtime-config-developer.html.

After the deletion of the corrupted pages PostgreSQL will not validate all foreign keys again. But the foreign key constraint may be broken by deletion of refrenced rows in the affected tables, which happened to be stored on the zeroed out data pages. 

A dump of this database with pg_dump will be possible. If every data row is accessible, because pg_dump only reads the data. But a restore of that dump with pg_restore is not possible anymore. At least not straight forward. Only with a work around.

# Description
This SQL script reads the definition of every foreign key in a database and builds a SELECT statement that returns foreign key values, which don't exist anymore in the refrenced table.

The set of bad foreign key rows is collected in a temporary result table. This table already contains a fitting delete statement to clean up the orphaned rows. You may want to check before deleting orphaned foreign key values the rows. So you can run the delete statements manually.

# Comparable to 
'DBCC CHECKCONSTRAINTS' of MS SQL Server

See https://docs.microsoft.com/en-us/sql/t-sql/database-console-commands/dbcc-checkconstraints-transact-sql

# Sources

I adapted the query to read the foreign key definition from here https://dba.stackexchange.com/a/218969
