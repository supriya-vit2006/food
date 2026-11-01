-- Pickup time support. Safe to run once on an existing database (Supabase SQL Editor -> New query -> Run).
alter table orders add column if not exists pickup_at timestamptz;
drop function if exists place_order(uuid,text,jsonb);
create or replace function place_order(p_canteen uuid,p_student text,p_items jsonb,p_pickup timestamptz default null) returns orders
language plpgsql security definer set search_path=public as $$
declare it jsonb;d dishes;lines jsonb:='[]';tot int:=0;k int;o orders;mx int:=0;pk timestamptz;ist date:=(now() at time zone 'Asia/Kolkata')::date;
begin
if coalesce(jsonb_array_length(p_items),0)=0 then raise exception 'Cart is empty'; end if;
for it in select * from jsonb_array_elements(p_items) loop
 update dishes set qty=case when qty is null then null else qty-(it->>'q')::int end
  where id=(it->>'id')::uuid and canteen_id=p_canteen and available and (it->>'q')::int>0 and (qty is null or qty>=(it->>'q')::int) returning * into d;
 if not found then raise exception 'An item is sold out or unavailable'; end if;
 lines:=lines||jsonb_build_object('name',d.name,'price',d.price,'q',(it->>'q')::int,'est',d.est_min);
 tot:=tot+d.price*(it->>'q')::int; mx:=greatest(mx,d.est_min);
end loop;
pk:=coalesce(p_pickup,now()+mx*interval '1 minute');
if pk<now()+mx*interval '1 minute'-interval '2 minutes' then raise exception 'Pickup time is too early. Your order needs about % minutes. Open the cart and choose a later time.',mx; end if;
if pk>now()+interval '8 hours' then raise exception 'Pickup time is too far away'; end if;
insert into counters(day,n) values(ist,1) on conflict(day) do update set n=counters.n+1 returning counters.n into k;
insert into orders(token,canteen_id,student_id,items,total,pickup_at) values(chr(65+(ist-date '2026-01-01')%26)||k,p_canteen,p_student,lines,tot,pk) returning * into o;
return o;
end$$;
revoke execute on function place_order(uuid,text,jsonb,timestamptz) from public,anon,authenticated;
grant execute on function place_order(uuid,text,jsonb,timestamptz) to service_role;
