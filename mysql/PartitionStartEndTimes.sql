
select sp.*, 
	   FROM_UNIXTIME(sp.start_time/1000) as starttime,
	   FROM_UNIXTIME(sp.end_time /1000) as endtime
from sqlth_partitions sp 
order by start_time desc