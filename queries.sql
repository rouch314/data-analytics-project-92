select
COUNT(c.customer_id) as customers_count
from customers c;

~Подсчет количества покупателей~

select
(e.first_name || ' ' || e.last_name) as seller,
COUNT(s.sales_person_id) as operations,
SUM(s.quantity * p.price) as income
from sales s
join employees e 
on s.sales_person_id  = e.employee_id
join products p
on s.product_id = p.product_id
group by (e.first_name || ' ' || e.last_name)
order by income desc
limit 10;

~Определение ТОП-10 продавцов по выручке~

select
(e.first_name || ' ' || e.last_name) as seller,
FLOOR(AVG(s.quantity * p.price)) as average_income
from sales s
join employees e 
on s.sales_person_id  = e.employee_id
join products p
on s.product_id = p.product_id
group by (e.first_name || ' ' || e.last_name)
having 
AVG(s.quantity * p.price) < (
	select
	AVG(s2.quantity * p2.price) as average_sum
	from sales s2
	join products p2
	on s2.product_id = p2.product_id
)
order by average_income;

~Отчет с продавцами, чья выручка ниже средней выручки всех продавцов~

with day_num as (
select
(e.first_name || ' ' || e.last_name) as seller,
to_char(s.sale_date, 'FMDay') as day_of_week,
FLOOR(SUM(s.quantity * p.price)) as income,
((EXTRACT(DOW FROM s.sale_date)::int + 6) % 7) as weekday_num
from sales s
join employees e 
on s.sales_person_id  = e.employee_id
join products p
on s.product_id = p.product_id
group by 
(e.first_name || ' ' || e.last_name), 
to_char(s.sale_date, 'FMDay'),
((EXTRACT(DOW FROM s.sale_date)::int + 6) % 7)
)
select
seller, day_of_week, income
from day_num
order by weekday_num, seller;

~Отчет с данными по выручке по каждому продавцу и дню недели~

WITH first_purchase AS (
    SELECT
    s.customer_id,
    s.sale_date,
    p.price,
    CONCAT(c.first_name, ' ', c.last_name) AS customer,
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    ROW_NUMBER() over (partition by s.customer_id order by s.sale_date) as rn
    from sales s 
    join customers c
    on s.customer_id = c.customer_id
    JOIN employees e ON s.sales_person_id = e.employee_id
    JOIN products p ON s.product_id = p.product_id
    )
select
customer, 
sale_date,
seller
from first_purchase
where rn = 1 and price = 0
order by customer;

~Отчет с покупателями, первая покупка которых пришлась на время проведения специальных акций~       