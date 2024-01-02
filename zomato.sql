CREATE DATABASE Zomato;
use Zomato;
create table goldusers_signup(user_id integer , gold_signup_date date);

INSERT INTO goldusers_signup(user_id,gold_signup_date) 
VALUES (1,'2017-09-22'),
(3,'2017-04-21');

drop table if exists users;
CREATE TABLE users(user_id integer,signup_date date);

INSERT INTO users (user_id, signup_date)
VALUES 
    (1, '2014-09-02'),
    (2, '2015-01-15'),
    (3, '2014-04-11');

drop table if exists sales;
CREATE TABLE sales(user_id integer,created_date date,product_id integer); 
INSERT INTO sales(user_id, created_date, product_id)
VALUES (1, '2017-04-19', 2),
       (3, '2019-12-18', 1),
       (2, '2020-07-20', 3),
       (1, '2019-10-23', 2),
       (1, '2018-03-19', 3),
       (3, '2016-12-20', 2),
       (1, '2016-11-09', 1),
       (1, '2016-05-20', 3),
       (2, '2017-09-24', 1),
       (1, '2017-03-11', 2),
       (1, '2016-03-11', 1),
       (3, '2016-11-10', 1),
       (3, '2017-12-07', 2),
       (3, '2016-12-15', 2),
       (2, '2017-11-08', 2),
       (2, '2018-09-10', 3);

drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);

select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

## what is the total amount the customer spend on zomato

select a.user_id,sum(b.price) Total
from sales a
inner join product b
on a.product_id = b.product_id
group by a.user_id;
;

## how many days each customer has visited zomato?

select user_id, count(distinct created_date) VistedTime
from sales
group by user_id;

## what was the first product purchased by the customer
select * from
(select * , rank() over(partition by user_id order by created_date) rnk from sales)a where rnk = 1;

# what is the most purchased item and how many times it was purchased by all customer

select user_id,product_id, count(product_id) cnt from sales where product_id =
(select product_id from sales
group by product_id
order by count(product_id) desc limit 1)
group by user_id;

# which item was the most popular for each customer

select * from
(select * , rank() over(partition by user_id order by cnt desc) rnk from 
(select user_id, product_id ,count(product_id) cnt from sales 
group by user_id,product_id)a)b where rnk=1;

# which item was first bought by the customer after becoming a member
select * from
(select *, rank() over(partition by sales.user_id order by sales.created_date asc) rnk from
(select sales.*
from sales
left join goldusers_signup on goldusers_signup.user_id = sales.user_id 
where goldusers_signup.gold_signup_date is not null and sales.created_date >= goldusers_signup.gold_signup_date 
)a)b
where rnk = 1;

# which item was purchased bfore becoming the member

select * from
(select *, rank() over(partition by sales.user_id order by sales.created_date desc) rnk from
(select sales.*
from sales
left join goldusers_signup on goldusers_signup.user_id = sales.user_id 
where goldusers_signup.gold_signup_date is not null and sales.created_date <= goldusers_signup.gold_signup_date 
)a)b
where rnk = 1;

 ## what is the total orders and amount spent for each member before they became a member
 
select user_id,count(created_date) order_count ,sum(price) amount from
(select a.* , d.price from
(select sales.* ,goldusers_signup.gold_signup_date
from sales
inner join goldusers_signup on goldusers_signup.user_id = sales.user_id 
and sales.created_date <= goldusers_signup.gold_signup_date 
)a inner join product d on a.product_id = d.product_id)c
group by user_id;


## if buying each product generates points for ex 5 rs equal to 2 zomato point and each product has differnet purchasing
#point such as for pq 5rs = 1, for p2 10 rs = 2, for p3 5rs = 1 
# calculate points collected by each customer and for which prpoducts most points given till now

#///// 
use zomato;

#### total points for each customer
select user_id,sum(amount/Points)*2.5 TotalCashBackEarned from
(select e.* , amount/Points from
(select d.* , 
case when product_id=1 then 5 
when product_id=2 then 10 
when product_id=3 then 5 else 0 end as Points from
(select c.user_id,c.product_id,sum(price) amount from
(select a.* , b.price 
from sales a 
inner join product b on a.product_id = b.product_id)c
group by user_id,product_id)d)e)f
group by user_id;

## product which has given highest point
select * 
from(
	select * , 
	rank() over(order by Total_Point_Given desc) as rnk 
    from(
    select product_id,
    sum(amount/Points) Total_Point_Given 
    from(
    select e.* , amount/Points 
    from(
    select d.* , 
	case 
		when product_id=1 then 5 
		when product_id=2 then 10 
		when product_id=3 then 5 else 0 
        end as Points 
	from(
    select c.user_id,
    c.product_id,
    sum(price) amount 
    from(
    select a.* , b.price 
	from sales a 
	inner join product b on a.product_id = b.product_id)c
	group by product_id)d)
    e)f
group by product_id)g )h
where rnk=1 ;


## in the first one year after a customer joins the gold membership program including their join date irrespective what 
## the customer has purchased they earn 5 zomato pointsfor every 10 rs spent who earned more 1 or 3
## and what was their points earning in the first year?

## 1 zomato point equal to 2 rupees
## 0.5 zomato point equal to 1 rupee


SELECT c.*,d.price*0.5 ZomatoPoint from
(SELECT a.user_id,a.product_id,a.created_date , b.gold_signup_date 
FROM sales a
INNER JOIN goldusers_signup b 
ON a.user_id = b.user_id  
AND created_date >= gold_signup_date
AND created_date <= DATE_ADD(gold_signup_date , interval 1 year)
ORDER BY user_id,created_date asc)c
INNER JOIN product d on c.product_id = d.product_id;


## rank all the transaction of all customer

select * , rank() over(partition by user_id order by created_date) rnk from sales;

## rank all the transactions for each member whenever they are a zomato gold member for every non gold member
## transaction mark as na

select c.* , 
case when gold_signup_date is null then "NA" else 
rank() over (partition by user_id order by created_date desc) end as rnk from
(select a.* , b.gold_signup_date from sales a
left join goldusers_signup b 
on a.user_id  = b.user_id
and created_date >= gold_signup_date)c;