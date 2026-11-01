-- ONE FILE. Run it ONCE on a fresh Supabase project (SQL Editor -> New query -> paste all -> Run).
do $$ begin if to_regclass('public.canteens') is not null then raise exception 'Already set up. Do not run this twice.'; end if; end $$;
-- ===== supabase =====
create table canteens(id uuid primary key default gen_random_uuid(),name text unique not null);
create table owners(user_id uuid primary key references auth.users on delete cascade,canteen_id uuid not null references canteens);
create table dishes(id uuid primary key default gen_random_uuid(),canteen_id uuid not null references canteens on delete cascade,name text not null,price int not null default 0,category text not null default 'General',veg boolean not null default true,est_min int not null default 15,qty int,available boolean not null default true);
create table orders(id uuid primary key default gen_random_uuid(),token text not null,canteen_id uuid not null references canteens,student_id text not null,items jsonb not null,total int not null,status text not null default 'processing',created_at timestamptz not null default now());
create table counters(day date primary key,n int not null);
create index on dishes(canteen_id);create index on orders(canteen_id,created_at desc);create index on orders(student_id);
alter table canteens enable row level security;alter table owners enable row level security;alter table dishes enable row level security;alter table orders enable row level security;alter table counters enable row level security;
create policy r on canteens for select using(true);
create policy r on dishes for select using(true);
create policy r on orders for select using(true);
create policy r on owners for select to authenticated using(user_id=auth.uid());
create policy w on dishes for all to authenticated using(exists(select 1 from owners o where o.user_id=auth.uid() and o.canteen_id=dishes.canteen_id)) with check(exists(select 1 from owners o where o.user_id=auth.uid() and o.canteen_id=dishes.canteen_id));
create policy u on orders for update to authenticated using(exists(select 1 from owners o where o.user_id=auth.uid() and o.canteen_id=orders.canteen_id));
create or replace function place_order(p_canteen uuid,p_student text,p_items jsonb) returns orders
language plpgsql security definer set search_path=public as $$
declare it jsonb;d dishes;lines jsonb:='[]';tot int:=0;k int;o orders;ist date:=(now() at time zone 'Asia/Kolkata')::date;
begin
for it in select * from jsonb_array_elements(p_items) loop
 update dishes set qty=case when qty is null then null else qty-(it->>'q')::int end
  where id=(it->>'id')::uuid and canteen_id=p_canteen and available and (it->>'q')::int>0 and (qty is null or qty>=(it->>'q')::int) returning * into d;
 if not found then raise exception 'An item is sold out or unavailable'; end if;
 lines:=lines||jsonb_build_object('name',d.name,'price',d.price,'q',(it->>'q')::int,'est',d.est_min);
 tot:=tot+d.price*(it->>'q')::int;
end loop;
insert into counters(day,n) values(ist,1) on conflict(day) do update set n=counters.n+1 returning counters.n into k;
insert into orders(token,canteen_id,student_id,items,total) values(chr(65+(ist-date '2026-01-01')%26)||k,p_canteen,p_student,lines,tot) returning * into o;
return o;
end$$;
grant execute on function place_order to anon,authenticated;
alter publication supabase_realtime add table orders,dishes;

insert into canteens(name) values('KC'),('Darling(DC)'),('Hangy & Swig'),('Garnish');
with s(c,n,p,k,v) as (values
('G','Chilli Chicken',140,'Starters',0),('G','Chicken Manchurian',140,'Starters',0),('G','Gobi Manchurian',140,'Starters',1),('G','Chilli Gobi',140,'Starters',1),('G','Paneer Manchurian',140,'Starters',1),('G','Chilli Paneer',140,'Starters',1),
('G','Egg Roll',110,'Rolls',0),('G','Chicken Roll',110,'Rolls',0),('G','Paneer Roll',110,'Rolls',1),('G','Gobi Roll',110,'Rolls',1),
('G','Wai Wai (Plain)',60,'Snacks',1),('G','Vegetable Wai Wai',60,'Snacks',1),('G','Chicken Wai Wai',70,'Snacks',0),('G','Maggi',30,'Snacks',1),('G','Vegetable Maggi',30,'Snacks',1),('G','Egg Maggi',50,'Snacks',0),('G','Chicken Maggi',60,'Snacks',0),
('G','Veg Noodles',100,'Noodles',1),('G','Egg Noodles',110,'Noodles',0),('G','Chicken Noodles',120,'Noodles',0),('G','Egg Chicken Noodles',120,'Noodles',0),('G','Mix Non-Veg Noodles',150,'Noodles',0),
('G','Veg Fried Rice',100,'Rice',1),('G','Egg Fried Rice',110,'Rice',0),('G','Gobi Fried Rice',100,'Rice',1),('G','Paneer Fried Rice',140,'Rice',1),('G','Chicken Fried Rice',120,'Rice',0),('G','Prawn Fried Rice',150,'Rice',0),
('H','Veg Gobi Chinese Combo',170,'Combos',1),('H','Veg Paneer Chinese Combo',200,'Combos',1),('H','Non-Veg Chinese Combo',200,'Combos',0),('H','Veg Burger Combo',200,'Combos',1),('H','Non-Veg Burger Combo',220,'Combos',0),
('H','Classic Mac & Cheese',200,'Mac & Cheese',1),('H','Makhani Mac & Cheese',220,'Mac & Cheese',1),
('H','French Fries',90,'Snacks',1),('H','Potato Wedges',90,'Snacks',1),('H','Honey Chilli Potato',150,'Snacks',1),
('H','Plain Maggi',45,'Maggi',1),('H','Veg Maggi',50,'Maggi',1),('H','Egg Maggi',80,'Maggi',0),('H','Chicken Maggi',85,'Maggi',0),
('H','Veg Rice / Noodles',90,'Main Course',1),('H','Egg Rice / Noodles',100,'Main Course',0),('H','Chicken Rice / Noodles',120,'Main Course',0),
('H','Garden Salad Cheese Burger',65,'Burger',1),('H','Crispy Chicken Burger',120,'Burger',0),('H','Aloo Masala Roll',60,'Rolls',1),('H','Chicken Roll',120,'Rolls',0),
('H','Grilled Veg Sandwich',60,'Sandwich',1),('H','Chicken Tikka Sandwich',110,'Sandwich',0),('H','Classic Double Egg Omelette',50,'Omelette',0),
('D','Vadai',18,'Breakfast',1),('D','Idly (2 Nos)',20,'Breakfast',1),('D','Pongal',40,'Breakfast',1),('D','Poori Masala',40,'Breakfast',1),('D','Rava Dosai',46,'Dosai',1),
('D','Plain Dosai',40,'Dosai',1),('D','Masala Dosai',48,'Dosai',1),('D','Onion Dosai',52,'Dosai',1),('D','Egg Dosai',52,'Dosai',0),('D','Ghee Dosai',92,'Dosai',1),('D','Chicken Cheese Dosai',110,'Dosai',0),
('D','Chapati',42,'Breads',1),('D','Parotta',48,'Breads',1),('D','Kothu Parotta Veg',81,'Breads',1),('D','Kothu Parotta Chicken',104,'Breads',0),('D','Plain Omelette',46,'Omelette',0),
('D','Variety Rice',48,'Rice',1),('D','Curd Rice',48,'Rice',1),('D','Veg Biryani',48,'Rice',1),('D','Egg Biryani',105,'Rice',0),('D','Chicken Biryani',135,'Rice',0),('D','Chicken Pulav',140,'Rice',0),
('D','Gobi 65',63,'Starters',1),('D','Paneer 65',85,'Starters',1),('D','Chicken 65',125,'Starters',0),('D','Chicken Tikka',120,'Starters',0),
('D','Veg Fried Rice',70,'Chinese',1),('D','Veg Noodles',70,'Chinese',1),('D','Egg Fried Rice',80,'Chinese',0),('D','Chicken Fried Rice',105,'Chinese',0),('D','Chicken Noodles',105,'Chinese',0),('D','Gobi Manchurian',98,'Chinese',1),('D','Chilly Chicken',115,'Chinese',0),
('D','Dhal Fry',66,'North Indian',1),('D','Paneer Butter Masala',91,'North Indian',1),('D','Butter Chicken Masala',125,'North Indian',0),
('D','Veg Pasta',100,'Pasta',1),('D','Simple Veg Pizza',130,'Pizza',1),('D','Chicken Pizza',165,'Pizza',0),('D','Veg Sandwich',40,'Sandwich',1),
('D','French Fries',71,'Snacks',1),('D','Veg Burger',81,'Snacks',1),('D','Chicken Burger',109,'Snacks',0),('D','Pav Bhaji',69,'Snacks',1),
('D','Vanilla Ice Cream',58,'Dessert',1),('D','Cold Coffee',58,'Beverages',1),('D','Fresh Lemon',30,'Beverages',1),('D','Lassi',52,'Beverages',1))
insert into dishes(canteen_id,name,price,category,veg)
select (select id from canteens where name=case s.c when 'G' then 'Garnish' when 'H' then 'Hangy & Swig' else 'Darling(DC)' end),n,p,k,v=1 from s;
update dishes set est_min=case when name ilike '%dosa%' then 20 when name ilike '%rice%' or name ilike '%biryani%' or name ilike '%noodles%' or name ilike '%pulav%' then 30 else 15 end;

-- Link an owner: first create the user in Supabase > Authentication > Users (email + password, auto-confirm), then:
-- insert into owners select id,(select id from canteens where name='Garnish') from auth.users where email='owner@gmail.com';

-- ===== update =====
-- Run this in Supabase SQL Editor (safe on fresh or existing DB): removes FC, renames Darling, adds KC menu
delete from canteens where name='FC';
update canteens set name='Darling(DC)' where name='Darling Main Canteen';
with s(n,p,k) as (values
('Cheese Pav Bhaji',85,'Cheese Items'),('Cheese Vada Pav',70,'Cheese Items'),('Cheese Dabeli',70,'Cheese Items'),('Green Cheese Dabeli',70,'Cheese Items'),('Cheese Paneer Masala Pav',100,'Cheese Items'),('Cheese Masala Papad',80,'Cheese Items'),('Cheese Papdi Chat',80,'Cheese Items'),('Spl Aloo Tikki Cheese Pav',70,'Cheese Items'),('Potato Cheese Ball',120,'Cheese Items'),('Paneer Cheese Ball',140,'Cheese Items'),
('Paneer Manchurian',120,'Paneer Items'),('Paneer 65',110,'Paneer Items'),('Paneer Pav Bhaji',85,'Paneer Items'),('Paneer Masala Pav',90,'Paneer Items'),('Paneer Kurkure',110,'Paneer Items'),('Paneer Finger',110,'Paneer Items'),
('Paneer Sandwich',90,'Sandwich'),('Mushroom Sandwich',80,'Sandwich'),('Mix Veg Sandwich',70,'Sandwich'),('Sweet Corn Sandwich',60,'Sandwich'),('Aloo Sandwich',60,'Sandwich'),('Veg Sandwich',50,'Sandwich'),('Khakhra Sandwich',90,'Sandwich'),('Club Sandwich',120,'Sandwich'),('Cheese Sandwich',90,'Sandwich'),('Garlic Cheese Sandwich',120,'Sandwich'),('Extra Cheese',20,'Sandwich'))
insert into dishes(canteen_id,name,price,category,veg)
select (select id from canteens where name='KC'),n,p,k,true from s
where not exists(select 1 from dishes d join canteens c on c.id=d.canteen_id where c.name='KC' and d.name=s.n);

-- ===== server =====
-- Run AFTER supabase.sql and update.sql. Locks the DB so only the Render server can use it, and sets up owner logins.
create extension if not exists pgcrypto with schema extensions;
drop table if exists owners cascade;
create table owners(id uuid primary key default gen_random_uuid(),email text unique not null,pass_hash text not null,canteen_id uuid not null references canteens on delete cascade);
alter table owners enable row level security;
drop policy if exists r on canteens;drop policy if exists r on dishes;drop policy if exists r on orders;drop policy if exists w on dishes;drop policy if exists u on orders;
revoke execute on function place_order(uuid,text,jsonb) from public,anon,authenticated;
-- One line per canteen owner: change email, password, canteen name. Re-run to reset a password (delete the old row first).

-- ===== owner-signup =====
-- Run once in Supabase SQL Editor. Owners now sign up themselves using a per-canteen access code.
alter table canteens add column if not exists signup_code text default substr(md5(random()::text),1,8);
update canteens set signup_code=substr(md5(random()::text),1,8) where signup_code is null;
delete from owners;
select name, signup_code from canteens order by name;  -- give each owner ONLY their canteen's code

