# ForeignKeyCheck
Check all foreign keys in a PostgreSQL database for logical integrity

# Use Case
If you create a foreign key on a table in PostgreSQL it checks if the affected columns fit the foreign key condition. PostgreSQL will make sure that the integrity of the foreign key is valid when rows on the respective tables are modified. You can trust the integritry of the foreign key.

However, if you face corruption in your database you may only solve the problem by allowing data loss. This is the case if you have to zero out the corrupted data pages with the 'zero_damaged_pages' developer option, see https://www.postgresql.org/docs/current/runtime-config-developer.html.

After the deletion of the corrupted pages PostgreSQL will not validate all foreign keys again. But the foreign key constraint may be broken by deletion of refrenced rows in the affected tables, which may happen to be on stored on the zeroed out data pages. This sql script scans every foreign key in a database ...

# Comparable to 

'DBCC CHECKCONSTRAINTS' MS SQL Server
see https://docs.microsoft.com/en-us/sql/t-sql/database-console-commands/dbcc-checkconstraints-transact-sql
