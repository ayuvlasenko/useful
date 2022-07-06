create or replace
    function __log_callstack_trigger()
returns trigger
as $$
declare
    _callstack text;
begin
    begin
        raise exception 'callstack';
    exception when others then
        get stacked diagnostics
            _callstack = PG_EXCEPTION_CONTEXT;
    end;

    if (
        new.some_column is distinct from old.some_column
    ) then
        perform some_log_json_function(json_build_object(
            'type', 'log_some_table_some_column_update_callstack',
            'id', new.id,
            'new.some_column', new.some_column,
            'old.some_column', old.some_column,
            'query', (
                select
                    json_build_object(
                        'usename', pg_stat_activity.usename,
                        'applcation_name', pg_stat_activity.application_name,
                        'client_addr', pg_stat_activity.client_addr,
                        'sql', pg_stat_activity.query
                    )
                from pg_stat_activity
                where
                    pg_stat_activity.pid = pg_backend_pid()
                limit 1
            ),
            'callstack', (
                select array_agg( line )
                from unnest(
                    regexp_split_to_array(_callstack, '[\n\r]+')
                ) as line
                where
                    line ilike '%line % at SQL statement%'
            )
        )::text);
    end if;

    return new;
end
$$ language plpgsql;

create trigger __log_callstack_trigger
before
    update of
        some_column
on some_table
for each row
execute procedure __log_callstack_trigger()
