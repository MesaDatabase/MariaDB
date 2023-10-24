SET @currentDate = DATE_FORMAT(CURRENT_DATE(), '%Y%m%d');
SET @currentTable = CONCAT('sqlt_data_1_', @currentDate);


SET @sql = CONCAT('
					SELECT sd.*,
						   FROM_UNIXTIME(sd.t_stamp/1000) as readtime 
					FROM ', @currentTable, ' sd ORDER BY t_stamp desc
				  ');
PREPARE dynamic_sql FROM @sql;
EXECUTE dynamic_sql;


