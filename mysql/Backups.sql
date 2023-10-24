-- Change to the AUTO database
USE SCADA;

-- Backup the sql_data_1 table to a file
SELECT * INTO OUTFILE '/backups/SCADA/sqlt_data_1_20230929.sql'
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM sqlt_data_1_20230929;
