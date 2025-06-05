create database retail;
use retail;
create table retail3(
	`Discount` float,
	`Unit Price` float,
	`Shipping Cost` float,
	`Customer ID` int,
	`Customer Name` varchar(255),
	`Ship Mode` varchar(255),
	`Customer Segment` varchar(255),
	`Product Category` varchar(255),
	`Product Sub-Category` varchar(255),
	`Product Container` varchar(255),
	`Product Name` varchar(255),
	`Product Base Margin` float,
	`Region` varchar(255),
	`State or Province` varchar(255),
	`City` varchar(255),
	`Postal Code` int,
	`Order Date` datetime,
	`Ship Date` datetime,
	`Profit` float,
	`Quantity ordered new` int,
	`Sales` float,
	`Order ID` int
	);
    
SELECT * FROM retail.retail3;
SELECT * FROM retail.book1;
SELECT count(*) as Total_Records
FROM retail.retail3;

-------- Overview: Total sales, Profit, Discount -----------------------------
select round(sum(Sales),2) as Total_Sales,
round(sum(Profit),2) as Total_Profit,
round(sum(Discount),2) as Total_Discount 
from retail.retail3; 

-------- Total Number of Orders and Customers ---------------------------------
select count(distinct `Order ID`) as Total_Orders,
count(distinct `Customer ID`) as Total_Customers
from retail.retail3; 

--------- Top 10 Products Category by sales ---------------------------------------------
select`Product Category`, `Order ID`,sum(sales) as Total_Sales
from retail.retail3
group by `Order ID`,`Product Category`
order by Total_Sales DESC
limit 10;

---------- Discount Distribution ---------------------------------------------------------
select floor(Discount * 100) as Discount_percent,
count(*) as order_count
from retail.retail3
group by Discount_percent
order by Discount_percent;

------------ Monthly sales and profit trend -----------------------------------------------
select date_format(`Order Date`,'%y-%m') as month,
round(sum(sales),2) as monthly_sales,
round(sum(Profit),2) as Monthly_profit
from retail.retail3
group by month
order by month;

---------- Top 5 States by Negative Profit --------------------------------------------
select `State or Province`,Round(sum(Profit),2) as Total_Profit
from retail.retail3
group by `State or Province`
having Total_Profit <0
order by Total_Profit ASC
LIMIT 5;

----------- Top 5 Most returned sub-category -------------------------------
select 
r3.`Product Sub-Category`,count(b1.`Order ID`) as returned_orders
from retail.retail3 r3
join book1 b1 on r3.`Order ID`=b1.`Order ID`
group by r3.`Product Sub-Category`
order by returned_orders desc
limit 5;

------------------- EDA- Business-Centric Questions & Queries ---------------------------

1) Which discount ranges are associated with negative profit margins?
select case 
when Discount between 0 and 0.1 then '0-10%'
when Discount between 0.1 and 0.2 then '10-20%'
when Discount between 0.2 and 0.3 then '20-30%'
when Discount > 0.3 then '30%+' end as discount_range, 
round(avg(Profit),2) as avg_Profit,
round(avg(Profit/Sales)*100,2) as avg_profit_margin,count(*) as total_orders
from retail.retail3
group by discount_range
order by avg_profit_margin;

2) What are the average profit and discount levels by product category?
select `Product Category`,`Product Sub-Category`,
round(avg(Discount),2) as avg_discount,
round(sum(Sales),2) as total_sales,
round(sum(Profit),2) as total_profit,
round(sum(Profit)/sum(Sales)*100,2) as Profit_margin
from retail.retail3
group by `Product Category`,`Product Sub-Category`
order by Profit_margin;

------------------ Are certain sub-categories more prone to returns than others -------------------------------

select r3.`Product Category`,
r3.`Product Sub-Category`,
count(*) as total_orders,
sum(case when b1.Status='Returned' then 1 else 0 end) as returned_orders,
round(sum(case when b1.Status='Returned' then 1 else 0 end)/count(*)* 100,2) as return_rate
from retail.retail3 r3 left join book1 b1 on r3.`Order ID` = b1.`Order ID`
where r3.`Product Sub-Category` in ('Rubber Bands','Scissors, Rulers and Trimmers','Tables','Bookcases')
group by r3.`Product Category`,r3. `Product Sub-Category`
order by return_rate desc;

3) Do returned orders show negative profit?
select case when b1.Status='Returned' then 'Returned' else 'Not Returned' end as return_status,
round(avg(r3.Profit),2) as avg_profit,
sum(r3.Profit) as total_profit,
count(*) as total_orders
from retail.retail3 r3 left join book1 b1 on r3.`Order ID` = b1.`Order ID`
group by return_status;

4) Which cities in each region are most and least profitable?
select Region,City,
sum(Profit) as total_profit,
rank() over(partition by Region order by sum(Profit) desc) as region_rank
from retail.retail3
group by Region,City;

5) Is there a strong correlation between discount and profit?
select 
(avg(Discount*Profit)-avg(Discount)*avg(Profit))/(stddev(Discount)*stddev(Profit)) as correlation_discount_profit
from retail.retail3;

6) Are late shipments correlated with lower profit?
select
(avg(`Ship Date` * Profit)-avg(`Ship Date`)*avg(Profit))/(stddev(`Ship Date`)*stddev(Profit)) as correlation_shipping_delay_profit
from retail.retail3;

7) What is the average profit per discount level bucket?
select
case when Discount < 0.1 then '0-10%'
when Discount < 0.2 then '10-20%'
when Discount < 0.3 then '20-30%'
else '30%+' end as discount_range,
count(*) as total_orders,
avg(Profit) as avg_Profit,
stddev(Profit) as stddev_profit
from retail.retail3
group by discount_range
order by discount_range;

8) Are we growing profitably?
select date_format(`Order Date`,'%Y-%m') as order_month,
round(sum(Sales),2) as total_sales,
round(sum(Profit),2) as total_profit
from retail.retail3
group by order_month
order by order_month;

----------------- Check average discount in jan and mar 2010----------------------------
select date_format(`Order Date`, '%Y-%m') as order_month,
sum(Discount) as Total_discount
from retail.retail3
where date_format(`Order Date`, '%Y-%m') in ('2010-01','2010-03')
group by order_month;

9) month over month growth in profit.
WITH monthly_profit AS (
  SELECT 
    DATE_FORMAT(`Order Date`, '%Y-%m') AS month,
    SUM(Profit) AS total_profit
  FROM retail.retail3
  GROUP BY month
),
profit_with_growth AS (
  SELECT 
    month,
    total_profit,
    LAG(total_profit) OVER (ORDER BY month) AS prev_month_profit,
    ROUND(((total_profit - LAG(total_profit) OVER (ORDER BY month)) / 
           NULLIF(LAG(total_profit) OVER (ORDER BY month), 0)) * 100, 2) AS profit_growth_percent
  FROM monthly_profit
)
SELECT * FROM profit_with_growth

---------------- Cumulative revenue generated -----------------------------
select `Order Date`,`Sales`,round(sum(`Sales`) over(order by`Order Date`),2) as Cumulative_revenue
FROM retail.retail3 
order by `Order Date`;



