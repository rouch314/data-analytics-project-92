/*select COUNT(c.customer_id) as customers_count
	from customers c;

--Подсчет количества покупателей

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

--Определение ТОП-10 продавцов по выручке

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

--Отчет с продавцами, чья выручка ниже средней выручки всех продавцов

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

--Отчет с данными по выручке по каждому продавцу и дню недели

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


--Отчет с покупателями, первая покупка которых пришлась
на время проведения специальных акций~
*/
--4 ШАГ
select count(customer_id) --считаем кол-во покупателей по уникальным id
from customers;


-- 5 ШАГ
-- 1 отчет top_10_total_income
select
    --склеиваем имя и фамилию продавца
    concat(e.first_name || ' ' || e.last_name) as seller,
    count(s.sales_id) as operations, --считаем операции
    floor(sum(p.price * s.quantity)) as income --считаем выручку
from sales as s
left join employees as e
    --джойним эту таблицу для имен продавцов
    on s.sales_person_id = e.employee_id
left join products as p
    on s.product_id = p.product_id --а эту для цен товаров
group by 1
order by 3 desc --сортируем по выручке по убыванию
limit 10; --показываем только первые 10

-- 2 отчет lowest_average_income
with cte_lowest_income as (
    select
        concat(e.first_name, ' ', e.last_name) as seller,
        floor(avg(p.price * s.quantity)) as average_income
    from sales as s
    left join employees as e
        on s.sales_person_id = e.employee_id
    left join products as p
        on s.product_id = p.product_id
    group by 1
)

select *
from cte_lowest_income
where average_income < (
    select avg(li2.average_income)
    from cte_lowest_income as li2
);

-- 3 отчет day_of_the_week_income
with sales3 as (
    select
        concat(e.first_name || ' ' || e.last_name) as seller,
        to_char(s.sale_date, 'day') as day_of_week,
        floor(sum(p.price * s.quantity)) as income,
        extract(dow from s.sale_date) + 1 as num_week
    from sales as s
    left join employees as e
        on s.sales_person_id = e.employee_id
    left join products as p
        on s.product_id = p.product_id
    group by 1, 2, 4
    order by 4, 1
)

select
    seller,
    day_of_week,
    income
from sales3;

-- 6 ШАГ
-- 1 отчет age_groups
select
    case
        when age between 16 and 25 then '16-25'
        when age between 26 and 40 then '26-40'
        when age >= 41 then '40+'
    end as age_category, -- создаем колонку с категориями возрастов
    count(age) as age_count  -- считаем кол-во клиентов по возрастным категориям
from customers
group by 1
order by 1;

-- 2 отчет customers_by_month
select
    --убираем из даты день, оставляя год и месяц
    to_char(s.sale_date, 'yyyy-mm') as selling_month,
    --считаем уникальных покупателей
    count(distinct s.customer_id) as total_customers,
    sum(p.price * s.quantity) as income --считаем выручку за месяц
from sales as s
left join products as p
    -- соединяем таблицу products для значения price из него
    on s.product_id = p.product_id
group by 1
order by 1; -- сортируем по дате

-- 3 отчет special_offer
with sp_of as (
    select
        c.customer_id,
        s.sale_date,
        p.price,
        concat(c.first_name || ' ' || c.last_name) as customer,
        concat(e.first_name || ' ' || e.last_name) as seller,
        row_number() over (partition by c.customer_id order by s.sale_date)
            as rn
    from sales as s
    left join customers as c --джойним эту таблицу для имен клиентов
        on s.customer_id = c.customer_id
    left join employees as e
        --джойним эту таблицу для имен продавцов
        on s.sales_person_id = e.employee_id
    left join products as p  --джойним эту таблицу для цен
        on s.product_id = p.product_id
    order by 1 --сортируем по id покупателей
)

--выводим имена покупателей, дату покупки и имя продавца
select
    sp_of.customer,
    sp_of.sale_date,
    sp_of.seller
from sp_of
where sp_of.rn = 1 and sp_of.price = 0;
