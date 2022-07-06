select
    min(query_start) as min_query_start,
    array_agg(pid) as pids,
    query
from pg_stat_activity
where
    query_start < now() - interval '60 seconds'
    and query not ilike 'listen %'
group by query
