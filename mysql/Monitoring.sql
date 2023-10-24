SHOW ERRORS;

SELECT @sql_mode

SHOW VARIABLES LIKE 'log_error';


install plugin SQL_ERROR_LOG soname 'sql_errlog';


SHOW ENGINE INNODB STATUS

SET GLOBAL innodb_status_output_locks = ON 
