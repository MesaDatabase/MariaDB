-- Change to the AUTO database
USE AUTO;

-- Backup the sql_data_1 table to a file
SELECT * INTO OUTFILE '/backups/AUTO/sql_data_table_yyyymmdd.sql'
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM sql_data_table_yyyymmdd.;
