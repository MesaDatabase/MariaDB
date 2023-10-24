INSERT INTO dataintegritybad 
					(table_date, tagid, dataintegrity, t_stamp)
					
SELECT  DATE_SUB(CURDATE(), INTERVAL 3 DAY) AS table_date,
tagid, dataintegrity, t_stamp 
FROM sqlt_data_1_20230912
where dataintegrity = '600'



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