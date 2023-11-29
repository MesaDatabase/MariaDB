-- MariaMetrics
/*
This package monitors database size, buffer pool utilization,
buffer pool hit ratio, queries per second, & transactions per second
over time
*/

-- Create the MariaMetrics database
CREATE DATABASE IF NOT EXISTS MariaMetrics;

-- Switch to the MariaMetrics database
USE MariaMetrics;

-- Enable the event scheduler if not already enabled
SET GLOBAL event_scheduler = ON;

-- Database size metrics
-- Create the database_size_history table
CREATE TABLE IF NOT EXISTS database_size_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    database_name VARCHAR(255) NOT NULL,
    timestamp DATETIME NOT NULL,
    size_gb DECIMAL(10, 2) NOT NULL
);

-- Create the procedure
DELIMITER //

CREATE PROCEDURE InsertDatabaseSize()
BEGIN
    DECLARE db_size DECIMAL(10, 2);

    -- Get the size of the 'SCADA' database
    SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024 / 1024, 2) INTO db_size
    FROM information_schema.tables
    WHERE table_schema = 'SCADA';

    -- Insert the record into the database_size_history table
    INSERT INTO MariaMetrics.database_size_history (database_name, timestamp, size_gb)
    VALUES ('SCADA', NOW(), db_size);
END //

DELIMITER ;

-- Call the InsertDatabaseSize procedure
CALL MariaMetrics.InsertDatabaseSize();

-- Create the event to run the procedure daily at 10:05 AM
DELIMITER //

CREATE EVENT IF NOT EXISTS DailyDatabaseSizeEvent
ON SCHEDULE EVERY 1 DAY
STARTS TIMESTAMP(CURDATE(), '10:07:00')
DO
BEGIN
    -- Call the InsertDatabaseSize procedure
    CALL MariaMetrics.InsertDatabaseSize();
END //

DELIMITER ;


-- Buffer pool metrics 
-- Buffer pool utilization percentage
-- Create the buffer_pool_utilization_history table
CREATE TABLE IF NOT EXISTS buffer_pool_utilization_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp DATETIME NOT NULL,
    utilization_percentage DECIMAL(5, 2) NOT NULL
);

-- Create the buffer pool utilization procedure
DELIMITER //

CREATE PROCEDURE InsertBufferPoolUtilization()
BEGIN
    DECLARE buffer_pool_data INT;
    DECLARE buffer_pool_total INT;
    DECLARE utilization_percentage DECIMAL(5, 2);

    -- Get the buffer pool data and total values
    SELECT
        variable_value INTO buffer_pool_data
    FROM
        information_schema.global_status
    WHERE
        variable_name = 'Innodb_buffer_pool_pages_data';

    SELECT
        variable_value INTO buffer_pool_total
    FROM
        information_schema.global_status
    WHERE
        variable_name = 'Innodb_buffer_pool_pages_total';

    -- Calculate the buffer pool utilization percentage
    SET utilization_percentage = ROUND(buffer_pool_data * 100.0 / buffer_pool_total, 2);

    -- Insert the record into the buffer_pool_utilization_history table
    INSERT INTO buffer_pool_utilization_history (timestamp, utilization_percentage)
    VALUES (NOW(), utilization_percentage);
END //

DELIMITER ;

-- Enable the event scheduler if not already enabled
SET GLOBAL event_scheduler = ON;

-- Drop the event if it already exists
DROP EVENT IF EXISTS BufferPoolUtilizationEvent;

-- Create the event to run the procedure every 60 seconds
DELIMITER //

CREATE EVENT IF NOT EXISTS BufferPoolUtilizationEvent
ON SCHEDULE EVERY 60 SECOND
DO
BEGIN
    -- Call the InsertBufferPoolUtilization procedure
    CALL InsertBufferPoolUtilization();

    -- Delete records older than a week
    DELETE FROM buffer_pool_utilization_history
    WHERE timestamp < NOW() - INTERVAL 1 WEEK;
END //

DELIMITER ;

-- Buffer pool hit ratio
CREATE TABLE IF NOT EXISTS buffer_pool_hit_ratio_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp DATETIME NOT NULL,
    hit_ratio DECIMAL(5, 2) NOT NULL
);

DELIMITER //

CREATE PROCEDURE InsertBufferPoolHitRatio()
BEGIN
    DECLARE buffer_pool_reads BIGINT;
    DECLARE buffer_pool_read_requests BIGINT;
    DECLARE hit_ratio DECIMAL(5, 2);

    -- Get the buffer pool reads and read requests values
    SELECT
        variable_value INTO buffer_pool_reads
    FROM
        information_schema.global_status
    WHERE
        variable_name = 'Innodb_buffer_pool_reads';

    SELECT
        variable_value INTO buffer_pool_read_requests
    FROM
        information_schema.global_status
    WHERE
        variable_name = 'Innodb_buffer_pool_read_requests';

    -- Calculate the buffer pool hit ratio
    SET hit_ratio = ROUND((1 - (buffer_pool_reads / buffer_pool_read_requests)) * 100, 2);

    -- Insert the record into the buffer_pool_hit_ratio_history table
    INSERT INTO buffer_pool_hit_ratio_history (timestamp, hit_ratio)
    VALUES (NOW(), hit_ratio);
END //

DELIMITER ;

-- Drop the event if it already exists
DROP EVENT IF EXISTS BufferPoolHitRatioEvent;

-- Create the event to run the procedure every 60 seconds
DELIMITER //

CREATE EVENT IF NOT EXISTS BufferPoolHitRatioEvent
ON SCHEDULE EVERY 60 SECOND
DO
BEGIN
    -- Call the InsertBufferPoolHitRatio procedure
    CALL InsertBufferPoolHitRatio();

    -- Delete records older than a week
    DELETE FROM buffer_pool_hit_ratio_history
    WHERE timestamp < NOW() - INTERVAL 1 WEEK;
END //

DELIMITER ;


-- Queries per second
CREATE TABLE IF NOT EXISTS qps_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp DATETIME NOT NULL,
    queries_per_second DECIMAL(10, 2) NOT NULL
);

-- Procedure measures QPS since last minute measurement
DELIMITER //

CREATE PROCEDURE InsertQPS()
BEGIN
    DECLARE current_questions INT;
    DECLARE previous_questions INT;
    DECLARE elapsed_time_seconds INT;
    DECLARE qps DECIMAL(10, 2);

    -- Get the current value of the 'Questions' status variable
    SELECT variable_value INTO current_questions
    FROM information_schema.global_status
    WHERE variable_name = 'Questions';

    -- Get the previous value of 'Questions' from the last recorded entry
    SELECT MAX(queries_per_second) INTO previous_questions
    FROM qps_history;

    -- Calculate the time elapsed since the last measurement
    SET elapsed_time_seconds = TIMESTAMPDIFF(SECOND, (SELECT MAX(timestamp) FROM qps_history), NOW());

    -- Calculate QPS, handling the case where previous_questions is NULL
    SET qps = IFNULL((current_questions - previous_questions) / elapsed_time_seconds, 0);

    -- Insert the record into the qps_history table
    INSERT INTO qps_history (timestamp, queries_per_second)
    VALUES (NOW(), qps);
END //

DELIMITER ;



-- Drop the event if it already exists
DROP EVENT IF EXISTS QPSEvent;

-- Create the event to run the procedure every 1 minute
DELIMITER //

CREATE EVENT IF NOT EXISTS QPSEvent
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
    -- Call the InsertQPS procedure
    CALL InsertQPS();
END //

DELIMITER ;


-- Transactions per second
-- Create table
CREATE TABLE IF NOT EXISTS tps_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp DATETIME NOT NULL,
    transactions_per_second DECIMAL(10, 2) NOT NULL
);

-- Procedure measures tps since last minute reading
DELIMITER //

CREATE PROCEDURE InsertTPS()
BEGIN
    DECLARE current_commits INT;
    DECLARE current_rollback INT;
    DECLARE previous_commits INT;
    DECLARE elapsed_time_seconds INT;
    DECLARE tps DECIMAL(10, 2);

    -- Get the current values of the 'Com_commit' and 'Com_rollback' status variables
    SELECT variable_value INTO current_commits FROM information_schema.global_status WHERE variable_name = 'Com_commit';
    SELECT variable_value INTO current_rollback FROM information_schema.global_status WHERE variable_name = 'Com_rollback';

    -- Get the previous values of 'Com_commit' and 'Com_rollback' from the last recorded entry
    SELECT transactions_per_second INTO previous_commits FROM tps_history ORDER BY id DESC LIMIT 1;

    -- If previous_commits is NULL, set it to 0
    SET previous_commits = IFNULL(previous_commits, 0);

    -- Calculate the time elapsed since the last measurement
    SET elapsed_time_seconds = TIMESTAMPDIFF(SECOND, (SELECT MAX(timestamp) FROM tps_history), NOW());

    -- Calculate TPS, handling the case where elapsed_time_seconds is 0
    SET tps = CASE WHEN elapsed_time_seconds > 0 THEN (current_commits + current_rollback - previous_commits) / elapsed_time_seconds ELSE 0 END;

    -- Insert the record into the tps_history table
    INSERT INTO tps_history (timestamp, transactions_per_second) VALUES (NOW(), tps);
END //

DELIMITER ;

-- TPS Event
-- Drop the event if it already exists
DROP EVENT IF EXISTS TPSEvent;

-- Create the event to run the procedure every 1 minute
DELIMITER //

CREATE EVENT IF NOT EXISTS TPSEvent
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
    -- Call the InsertTPS procedure
    CALL InsertTPS();
END //

DELIMITER ;


-- InnoDB Row Operations
-- Table categorizing row operations by type
CREATE TABLE IF NOT EXISTS innodb_row_operations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp DATETIME NOT NULL,
    operation_type VARCHAR(20) NOT NULL,
    operation_count BIGINT NOT NULL
);

-- Procedure
DELIMITER //

CREATE PROCEDURE InsertInnoDBRowOperations()
BEGIN
    SET @current_insert_count := (SELECT CAST(variable_value AS SIGNED) FROM information_schema.global_status WHERE variable_name = 'Innodb_rows_inserted');
    SET @current_update_count := (SELECT CAST(variable_value AS SIGNED) FROM information_schema.global_status WHERE variable_name = 'Innodb_rows_updated');
    SET @current_delete_count := (SELECT CAST(variable_value AS SIGNED) FROM information_schema.global_status WHERE variable_name = 'Innodb_rows_deleted');

    SET @previous_insert_count := COALESCE((SELECT MAX(operation_count) FROM innodb_row_operations WHERE operation_type = 'Insert'), 0);
    SET @previous_update_count := COALESCE((SELECT MAX(operation_count) FROM innodb_row_operations WHERE operation_type = 'Update'), 0);
    SET @previous_delete_count := COALESCE((SELECT MAX(operation_count) FROM innodb_row_operations WHERE operation_type = 'Delete'), 0);

    -- Calculate counts within the last minute
    SET @insert_count_within_last_minute := @current_insert_count - @previous_insert_count;
    SET @update_count_within_last_minute := @current_update_count - @previous_update_count;
    SET @delete_count_within_last_minute := @current_delete_count - @previous_delete_count;

    -- Insert the counts into the innodb_row_operations table
    INSERT INTO innodb_row_operations (timestamp, operation_type, operation_count)
    VALUES (NOW(), 'Insert', @insert_count_within_last_minute),
           (NOW(), 'Update', @update_count_within_last_minute),
           (NOW(), 'Delete', @delete_count_within_last_minute);
END //

DELIMITER ;



call InsertInnoDBRowOperations()



-- Event
-- Enable the event scheduler if not already enabled
SET GLOBAL event_scheduler = ON;

-- Drop the event if it already exists
DROP EVENT IF EXISTS InnoDBRowOperationsEvent;

-- Create the event to run the procedure every 1 minute
DELIMITER //

CREATE EVENT IF NOT EXISTS InnoDBRowOperationsEvent
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
    -- Call the InsertInnoDBRowOperations procedure
    CALL InsertInnoDBRowOperations();
END //

DELIMITER ;

-- Event
-- Enable the event scheduler if not already enabled
SET GLOBAL event_scheduler = ON;

-- Drop the event if it already exists
DROP EVENT IF EXISTS InnoDBRowOperationsEvent;

-- Create the event to run the procedure every 1 minute
DELIMITER //

CREATE EVENT IF NOT EXISTS InnoDBRowOperationsEvent
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
    -- Call the InsertInnoDBRowOperations procedure
    CALL InsertInnoDBRowOperations();
END //

DELIMITER ;


-- Disk space
-- Create a table for disk space information
-- Table will be populated daily by disk_space.sh 
CREATE TABLE IF NOT EXISTS disk_space_info (
    id INT AUTO_INCREMENT PRIMARY KEY,
    size VARCHAR(20),
    used VARCHAR(20),
    avail VARCHAR(20),
    use_percent VARCHAR(10),
    mounted_on VARCHAR(50),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
