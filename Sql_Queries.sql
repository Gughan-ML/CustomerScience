/* 1. In 2018, out of all customers who opted for pick up (PUT + S2S), how many (count and %age) have never placed a pick-up
order of over $35?
Some filters to help:
• where visit_date between X and Y
• and channel = 'DOTCOM'
• and service_id in (8, 11)*/

----
/*Assumptions - since table name is not given i am giving the table name as orders
Grain of the table is assumed to be customer sale*/

with max_sales_cap as (select ugc_id,
max(amount) as max_sales
from orders
where visit_date between '2018-01-01' and '2018-12-31'
and channel = 'DOTCOM'
and service_id in (8, 11)
group by ugc_id
/*selecting the maximum sales of customers in the year 2018 who has opted for pickup using dotcom channel
This subquery blocked named as max_sales_cap*/)
select sum(case when max_sales<=35 then 1 else 0 end) as cust_count,
(sum(case when max_sales<=35 then 1 else 0 end)/count(1))*100 as percentage
from max_sales_cap
/* calculating the number and percentage of customers who has not made pickup purchases over 35 using case when*/
=====================================================================================================================

/* 2. Cumulative revenue for “DOTCOM” and “OG” separately until end of each month of 2017 i.e. 
total revenue until end of Jan’17, Feb’17, until end of March’17… until end of Dec’17 */

/*Assumptions
Since no date range is given the output is presented for year 2017 alone
*/
----

with sales_month as (
select channel, year(visit_date) as year,
month(visit_date) as month,
sum(amount) as sales
from orders
where visit_date between '2017-01-01' and '2017-12-31'
and channel!='STORE'
group by channel,year,month
/*
calculating the sum of sales by each channel,year,month
This subquery blocked named as sales month
*/)
select channel, year,month, sales,
sum(sales) over (partition by channel order by year asc , month asc) as cum_sales
from sales_month;
/* Calcuating the cumulative sales using window functions sum over monthly sales calculated
above and partitioned it by channels*/

=======================================================================================================================

/* 3. For each quarter of a year - what percentage of shoppers (dotcom only) shopping in a fiscal quarter, will shop again (repeat) in the following quarter?
You’d have to look at Q1 for the next year to get repeat rate for Q4 of current year */

----

with qtr_customer as (
select ugc_id,
year(visit_date) year,
QUARTER(visit_date) quarter,
concat(year(visit_date),QUARTER(visit_date)) current_qtr
from orders
where visit_date between '2004-01-01' and date_add("2004-12-31", INTERVAL 1 QUARTER)
group by ugc_id, year, quarter,current_qtr
)/* selecting the customers who has done atleast one sales in the year and quarter
 
This subquery blocked named as qtr_customer
*/
,lead_customer as (
select ugc_id,
year,
quarter,
current_qtr,
lead(current_qtr) over (partition by ugc_id order by year,quarter) as next_qtr
from
qtr_customer)
/* sub query finds the next quarter a customer has transacted in.
This subquery block named as lead_customer
*/
select year,
quarter,
count(1) as current_shoppers,
sum(case when (next_qtr - current_qtr=7)  or (next_qtr - current_qtr=1) then 1 else 0 end) as repeat_shoppers,
(sum(case when (next_qtr - current_qtr=7) or (next_qtr - current_qtr=1)   then 1 else 0 end)/count(1))*100 as percent_repeat_shoppers
from lead_customer
group by year,quarter
order by year,quarter;

