-- Max-per-day stock + daily reset. Run once in Supabase SQL Editor.
alter table dishes add column if not exists daily_qty int;
alter table dishes add column if not exists qty_day date;
update dishes set daily_qty=qty,qty_day=(now() at time zone 'Asia/Kolkata')::date where daily_qty is null and qty is not null;
create or replace function daily_reset() returns void language sql security definer set search_path=public as $$
update dishes set qty=daily_qty,qty_day=(now() at time zone 'Asia/Kolkata')::date where daily_qty is not null and (qty_day is null or qty_day<(now() at time zone 'Asia/Kolkata')::date);
$$;
revoke execute on function daily_reset() from public,anon,authenticated;
grant execute on function daily_reset() to service_role;
notify pgrst, 'reload schema';
