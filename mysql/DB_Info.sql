-- Get database sizes 
SELECT
    table_schema AS DatabaseName,
    SUM(data_length + index_length) / 1024 / 1024 / 1024 AS SizeInGB
FROM
    information_schema.tables
GROUP BY
    table_schema;
    
  
 -- Get tables & sizes from specific database
   SELECT
    table_name AS TableName,
    ROUND((data_length + index_length) / 1024 / 1024 / 1024, 2) AS SizeInGB
FROM
    information_schema.tables
WHERE
    table_schema = 'SCADA'  -- Replace 'your_database_name' with your database name
    AND table_name not like 'sqlt_data_1_%'
    AND table_name not like '%2023%'
ORDER BY
    table_name asc;

   
 
 -- Current sql executions
   SHOW FULL PROCESSLIST;
   
  kill 1798557;
  
 
 
 -- Raise a custom error with SQLSTATE '45000' and a custom error message.
SIGNAL SQLSTATE '45000'
  SET MESSAGE_TEXT = 'This is a custom error message';
