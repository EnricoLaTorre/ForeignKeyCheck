/*
.SYNOPSIS
    Check the foreign keys of a database for logical integrity
.DESCRIPTION
    This script scans every foreign key of the database for consistency.
	It is able to handle single and multi-column foreign keys. It creates 
	a temporary table 'fk_check_results'. If the script found bad rows it 
	will be written out to csv file. The result table already provides
	fitting delete statements to clean up the foreig key breaches.

    Role that executes the script needs reading permission on all tables.

	Supported versions: PostgreSQL 9.5 and up
.NOTES
    Author:			Enrico La Torre
    Last change:		2020-04-21 15:15
*/
DO $body$
DECLARE
fk_name text;
fK_table text;
fk_column_array text[];
referenced_table text;
referenced_column_array text[];
selectstring text;
joinstring text;
wherestring text;
BEGIN
selectstring := 'ARRAY[';
joinstring := '';
wherestring := '';
create TEMPORARY table IF NOT EXISTS fk_check_results ( "FK_ID(Bad)" text[], FK_Table text, FK_Col text, FK_Name text, delstatement text);  
FOR fk_name, fK_table, fk_column_array, referenced_table, referenced_column_array IN
SELECT c.conname                                 		AS constraint_name,
   sch.nspname || '.' || tbl.relname             		AS "fk_table",
   ARRAY_AGG(col.attname ORDER BY u.attposition) 		AS "fk_columns",
   f_sch.nspname || '.' || f_tbl.relname         		AS "referenced_table",
   ARRAY_AGG(f_col.attname ORDER BY f_u.attposition) 	AS "referenced_columns"
   --,pg_get_constraintdef(c.oid)                   		AS definition
FROM pg_constraint c
       LEFT JOIN LATERAL UNNEST(c.conkey) WITH ORDINALITY AS u(attnum, attposition) ON TRUE
       LEFT JOIN LATERAL UNNEST(c.confkey) WITH ORDINALITY AS f_u(attnum, attposition) ON f_u.attposition = u.attposition
       JOIN pg_class tbl ON tbl.oid = c.conrelid
       JOIN pg_namespace sch ON sch.oid = tbl.relnamespace
       LEFT JOIN pg_attribute col ON (col.attrelid = tbl.oid AND col.attnum = u.attnum)
       LEFT JOIN pg_class f_tbl ON f_tbl.oid = c.confrelid
       LEFT JOIN pg_namespace f_sch ON f_sch.oid = f_tbl.relnamespace
       LEFT JOIN pg_attribute f_col ON (f_col.attrelid = f_tbl.oid AND f_col.attnum = f_u.attnum)
WHERE c.contype = 'f'
GROUP BY constraint_name, "fk_table", "referenced_table"
LOOP
	FOR i in 1 .. array_upper(fk_column_array,1)
		LOOP
		selectstring := selectstring || ', FK.' || fk_column_array[i];
		joinstring := joinstring || ' and FK.' || fk_column_array[i] || ' = PK.' || referenced_column_array[i];
		wherestring := wherestring || ' and FK.' || fk_column_array[i] || ' IS NOT NULL and PK.' || referenced_column_array[i] || ' IS NULL';
	END LOOP;
	SELECT regexp_replace(selectstring,', ','') into selectstring; -- Remove the leading comma in the column selection
	RAISE NOTICE 'select %]  from  % as FK left join % as PK on true % where true %;', selectstring,fK_table,referenced_table,joinstring,wherestring;
	execute format('insert into fk_check_results SELECT %1$s], ''%2$s'', ''%6$s'', ''%7$s'' 
				, ''DELETE FROM %2$s WHERE (%6$s) = ('' || array_to_string(%1$s],'','') ||'');''  
				FROM %2$s as FK
				LEFT JOIN %3$s as PK on true %4$s 
				WHERE true %5$s;
	',selectstring,fK_table,referenced_table,joinstring,wherestring,fk_column_array,fk_name);
	-- clear process variables
	selectstring := 'ARRAY[';
	joinstring := '';
	wherestring := '';
	RAISE NOTICE 'Scanned foreign key ''%'' on table ''%''', fk_name, fK_table;
END LOOP;
END
$body$ language 'plpgsql';

-- Write output of fk_check_results if bad foreign key values exist
DO $do$
	DECLARE
	databasename text;
	BEGIN
	SELECT current_database() INTO databasename;
	IF EXISTS (SELECT FROM fk_check_results) THEN
		EXECUTE format('COPY fk_check_results TO ''{logpath}\fk_check_results_%1$s.csv'' DELIMITER '','' CSV HEADER;',databasename);
		RAISE EXCEPTION 'Bad foreign key rows found in database ''%''!', databasename USING HINT = 'Check the file in {logpath}';
	END IF;
	END
$do$;
