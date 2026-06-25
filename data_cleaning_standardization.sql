create database SALES;
use SALES;
select *from sales;
-- ---------------------------------------------------------
-- --Step 1 :- To check for duplicates
-- --Step 2 :- Check For Null Values
-- --Step 3 :- Treating Null values
-- --Step 4 :- Handling Negative values
-- --Step 5 :- Fixing Inconsistent Date Formats & Invalid Dates
-- --Step 6 :- Fixing Invalid Email Addresses
-- --Step 7 :- Checking the datatype
-- --------------------------------------------------------------------------------------------
-- --Step 1 :- To check for duplicates
-- creating another dublicate data
Create table sales2 
like sales;

Insert into sales2
(select * from sales);

select * from sales2;

with cte as( 
     select* ,
	row_number() over(partition by transaction_id order by transaction_id) as row_num
	from sales2
 )
select * from cte 
where row_num>1;
-- 1001
-- 1004 dublicates
-- 1030
select * from sales2 
where transaction_id in (1001,1004,1030);

create table sales3
(transaction_id int ,
customer_id int ,
customer_name text ,
email text ,
purchase_date text ,
product_id int ,
category text,
price double ,
quantity int, 
total_amount text, 
payment_method text, 
delivery_status text,
customer_address text,
row_num  int);

insert into sales3
select*,
row_number() over(partition by transaction_id ,
customer_id  ,
customer_name  ,
email  ,
purchase_date  ,
product_id  ,
category ,
price  ,
quantity , 
total_amount , 
payment_method , 
delivery_status ,
customer_address) as row_num
from sales2;

select*from sales3 
where row_num>1;

delete from sales3
where row_num>1;

select*from sales3;

select * from sales3
where transaction_id in (1001,1004,1030);
-- --------------------------------------------------------------------------------------------
-- --Step 2 :- Check For Null Values
Select * from sales3
where transaction_id is null;

SELECT * FROM sales3
WHERE (transaction_id IS NULL OR TRIM(transaction_id) = '')
   OR (customer_id IS NULL OR TRIM(customer_id) = '')
   OR (customer_name IS NULL OR TRIM(customer_name) = '')
   OR (email IS NULL OR TRIM(email) = '')
   OR (purchase_date IS NULL OR TRIM(purchase_date) = '')
   OR (product_id IS NULL OR TRIM(product_id) = '')
   OR (category IS NULL OR TRIM(category) = '')
   OR (price IS NULL OR TRIM(price) = '')
   OR (quantity IS NULL OR TRIM(quantity) = '')
   OR (total_amount IS NULL OR TRIM(total_amount) = '')
   OR (payment_method IS NULL OR TRIM(payment_method) = '')
   OR (delivery_status IS NULL OR TRIM(delivery_status) = '')
   OR (customer_address IS NULL OR TRIM(customer_address) = '');
   
   -- Temporarily disable safe updates so you can modify the whole table
SET SQL_SAFE_UPDATES = 0;

--  Update empty or whitespace-only cells to NULL
UPDATE sales3
SET 
    transaction_id   = IF(TRIM(transaction_id)   = '', NULL, transaction_id),
    customer_id      = IF(TRIM(customer_id)      = '', NULL, customer_id),
    customer_name    = IF(TRIM(customer_name)    = '', NULL, customer_name),
    email            = IF(TRIM(email)            = '', NULL, email),
    purchase_date    = IF(TRIM(purchase_date)    = '', NULL, purchase_date),
    product_id       = IF(TRIM(product_id)       = '', NULL, product_id),
    category         = IF(TRIM(category)         = '', NULL, category),
    price            = IF(TRIM(price)            = '', NULL, price),
    quantity         = IF(TRIM(quantity)         = '', NULL, quantity),
    total_amount     = IF(TRIM(total_amount)     = '', NULL, total_amount),
    payment_method   = IF(TRIM(payment_method)   = '', NULL, payment_method),
    delivery_status  = IF(TRIM(delivery_status)  = '', NULL, delivery_status),
    customer_address = IF(TRIM(customer_address) = '', NULL, customer_address);

--  Re-enable safe updates for security
SET SQL_SAFE_UPDATES = 1;

SELECT * FROM sales3
WHERE transaction_id IS NULL
   OR customer_id IS NULL
   OR customer_name IS NULL
   OR email IS NULL
   OR purchase_date IS NULL
   OR product_id IS NULL
   OR category IS NULL
   OR price IS NULL
   OR quantity IS NULL
   OR total_amount IS NULL
   OR payment_method IS NULL
   OR delivery_status IS NULL
   OR customer_address IS NULL;
   
##treating null values
select distinct category from sales3;
SET SQL_SAFE_UPDATES = 0;
#------------------category 
update sales3
set category ='unknown' 
where category is null;

#--------------customer_address
select distinct customer_address from sales3;
update sales3
set customer_address='Not available' 
where customer_address is null;

#--------------payment_method
select distinct payment_method from sales3;
update sales3
set payment_method ='Not specified' 
where payment_method is null;

update sales3
set payment_method ='Credit Card' 
where payment_method in ('creditcard','CC','credit');

#--------------delevery status
select distinct delivery_status from sales3;
update sales3
set delivery_status ='Not delivered' 
where delivery_status is null;

#---------price
select distinct price from sales3;
##avg   2510.7
select avg(price) from sales3;

##mode
select price ,count(*) as max_count
from sales3
group by price
order by max_count desc;

select category,avg(price) as avg_price
from sales3
group by category;

-- Clothing	2539.2781871345046
-- Electronics	2663.9278409090907
-- Books	2591.649315068491
-- Toys	2237.1956849315084
-- unknown	2511.4164052287583
-- Home & Kitchen	2507.058378378379

update sales3
set price =2511.416
where price is null and category ='unknown';

update sales3
set price =2591.6493
where price is null and category ='Books';

update sales3
set price =2591.6493
where price is null ;

select * from sales3
where price is null;

-- --------------------------------------------------------------------------------------------
-- --Step 4 :- Handling Negative values

select* from sales3
where quantity<0;

Update sales3
set quantity =ABS(quantity)
where quantity<0;

update sales3
set total_amount=price*quantity
where total_amount is null or total_amount != price*quantity;

update sales3
set customer_name='user'
where customer_name is null;

-- --------------------------------------------------------------------------------------------

-- --Step 5 :- Fixing Inconsistent Date Formats & Invalid Dates
select * from sales3
where purchase_date='2024-02-30';

update sales3
SET purchase_date = '29/02/2024'
WHERE purchase_date = '2024-02-30';


--- -------------------------------------------------------------------------------------------
-- --Step 6 :- Fixing Invalid Email Addresses
SELECT * FROM sales3
WHERE email NOT LIKE '%@%';

update sales3
set email='not_given'
where email not like '%@%';

-- --------------------------------------------------------------------------------------------
-- --Step 7 :- Checking the datatype
select column_name, data_type
from information_schema.columns
where table_name='sales3';

UPDATE sales3
SET purchase_date = STR_TO_DATE(purchase_date, '%d/%m/%Y')
WHERE purchase_date LIKE '%/%/%';

--  Now, alter the column type safely
ALTER TABLE sales3
MODIFY COLUMN purchase_date DATE;





