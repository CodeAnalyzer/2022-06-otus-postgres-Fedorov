-- �� ����: ��������, ��������� ���������� ������
DROP SCHEMA IF EXISTS pract_functions CASCADE;
CREATE SCHEMA pract_functions;

SET search_path = pract_functions, publ;

-- ������:
CREATE TABLE goods
(
    goods_id    integer PRIMARY KEY,
    good_name   varchar(63) NOT NULL,
    good_price  numeric(12, 2) NOT NULL CHECK (good_price > 0.0)
);
INSERT INTO goods (goods_id, good_name, good_price)
VALUES 	(1, '������ �������������', .50),	(2, '���������� Ferrari FXX K', 185000000.01);

-- �������
CREATE TABLE sales
(
    sales_id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    good_id     integer REFERENCES goods (goods_id),
    sales_time  timestamp with time zone DEFAULT now(),
    sales_qty   integer CHECK (sales_qty > 0)
);

INSERT INTO sales (good_id, sales_qty) VALUES (1, 10), (1, 1), (1, 120), (2, 1);

-- �����:
SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;

-- � ����������� ������ ������ ����� ���� ����������� ��������
-- ������� ������� ��������������� ��, ������� �������
CREATE TABLE good_sum_mart
(
	good_name varchar(63) NOT NULL,
	sum_sale	numeric(16, 2) NOT NULL
);

-- ��������� ���������� �������
insert into good_sum_mart (good_name, sum_sale)
select G.good_name, sum(G.good_price * S.sales_qty)
from goods G
inner join sales S ON S.good_id = G.goods_id
group by G.good_name;

select * from good_sum_mart;

-------------------------------------------------------------------------
--           ������� ������� (�� ������� sales) ��� ���������          --
-------------------------------------------------------------------------

-- INSERT ---------------------------------------------------------------

create or replace function trigger_after_insert_sales()
returns trigger 
as
$BODY$
begin
	-- ��������� �� ����������/���������� � �������
	create temp table if not exists tmp_good_sum_ins as
  select g.good_name as good_name, sum(g.good_price * n.sales_qty) as sum_sale
    from new_table n
   inner join goods g on g.goods_id = n.good_id
   group by g.good_name;
  
  -- ��������� �������, ���� ������ � ������ ��� ����
  update good_sum_mart as gsm
     set sum_sale = gsm.sum_sale + tmp.sum_sale
    from tmp_good_sum_ins tmp 
   where gsm.good_name = tmp.good_name;
  
  -- ��������� ������������� � ������� ������
  insert into good_sum_mart (good_name, sum_sale)
  select tmp.good_name, tmp.sum_sale
    from tmp_good_sum_ins tmp
    left join good_sum_mart gsm on gsm.good_name = tmp.good_name
   where gsm.good_name is null;
  
  drop table tmp_good_sum_ins;
  return null;
end;
$BODY$
language plpgsql;

create or replace trigger after_insert_sales 
after insert on sales referencing new table as new_table
for each statement
execute function trigger_after_insert_sales();

-- UPDATE ---------------------------------------------------------------

create or replace function trigger_after_update_sales()
returns trigger 
as
$BODY$
begin
	-- ��������� �� ���������� � �������
	create temp table if not exists tmp_good_sum_upd as
  select g.good_name as good_name, sum(g.good_price * s.sales_qty) as sum_sale
    from new_table n
   inner join goods g on g.goods_id = n.good_id
   inner join sales s ON s.good_id = g.goods_id
   group by g.good_name;
  
  -- ��������� �������
  update good_sum_mart as gsm
     set sum_sale = tmp.sum_sale
    from tmp_good_sum_upd tmp 
   where gsm.good_name = tmp.good_name;
  
  drop table tmp_good_sum_upd;
  return null;
end;
$BODY$
language plpgsql;

create or replace trigger after_update_sales 
after update on sales referencing new table as new_table
for each statement
execute function trigger_after_update_sales();

-- ���� -----------------------------------------------------------------

select * from good_sum_mart;
update sales set sales_qty = 50 where sales_id = 1;
select * from good_sum_mart;

-- DELETE ---------------------------------------------------------------

create or replace function trigger_after_delete_sales()
returns trigger 
as
$BODY$
begin
	-- ��������� �� ���������� � �������
	create temp table if not exists tmp_good_sum_del as
  select g.good_name as good_name, sum(g.good_price * s.sales_qty) as sum_sale
    from old_table n
   inner join goods g on g.goods_id = n.good_id
   inner join sales s ON s.good_id = g.goods_id
   group by g.good_name;
  
  -- ��������� �������
  update good_sum_mart as gsm
     set sum_sale = tmp.sum_sale
    from tmp_good_sum_del tmp 
   where gsm.good_name = tmp.good_name;
  
  drop table tmp_good_sum_del;
  return null;
end;
$BODY$
language plpgsql;

create or replace trigger after_delete_sales 
after delete on sales referencing old table as old_table
for each statement
execute function trigger_after_delete_sales();

-- ���� -----------------------------------------------------------------

select * from good_sum_mart;
delete from sales where sales_id = 1;
select * from good_sum_mart;

-------------------------------------------------------------------------