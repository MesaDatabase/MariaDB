--Ignition Scada

--Search data integrity
INSERT INTO dataintegritybad 
					(table_date, tagid, dataintegrity, t_stamp)
					
SELECT  DATE_SUB(CURDATE(), INTERVAL 3 DAY) AS table_date,
tagid, dataintegrity, t_stamp 
FROM sqlt_data_1_20230912
where dataintegrity = '600'


--Search specific tags
SELECT d.table_date, 
	   d.tagid,
	   d.dataintegrity,
	   FROM_UNIXTIME(d.t_stamp/1000) as timestamp,
	   t.tagpath
FROM dataintegritybad d
LEFT JOIN SCADA.sqlth_te t ON t.id = d.tagid
WHERE d.tagid != 6116
AND d.tagid != 6459
order by table_date desc


--Partition start/endtimes
select sp.*, 
	   FROM_UNIXTIME(sp.start_time/1000) as starttime,
	   FROM_UNIXTIME(sp.end_time /1000) as endtime
from sqlth_partitions sp 
order by start_time desc

--Current day tag data
SET @currentDate = DATE_FORMAT(CURRENT_DATE(), '%Y%m%d');
SET @currentTable = CONCAT('sqlt_data_1_', @currentDate);


SET @sql = CONCAT('
					SELECT sd.*,
						   FROM_UNIXTIME(sd.t_stamp/1000) as readtime 
					FROM ', @currentTable, ' sd ORDER BY t_stamp desc
				  ');
PREPARE dynamic_sql FROM @sql;
EXECUTE dynamic_sql;


