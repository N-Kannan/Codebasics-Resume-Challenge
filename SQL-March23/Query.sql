
### Q1

SELECT DISTINCT market FROM `dim_customer` where region="APAC"and customer="Atliq Exclusive"

##Q2

WITH unique_products_2020 AS (
  SELECT COUNT(DISTINCT product_code) AS unique_products_2020 
  FROM `fact_sales_monthly` 
  WHERE fiscal_year=2020
), 
unique_products_2021 AS (
  SELECT COUNT(DISTINCT product_code) AS unique_products_2021 
  FROM `fact_sales_monthly` 
  WHERE fiscal_year=2021
) 
SELECT 
  unique_products_2020, 
  unique_products_2021,
  ((unique_products_2021 - unique_products_2020) / unique_products_2020) * 100 AS percentage_change
FROM unique_products_2020, unique_products_2021;


##Q3

SELECT DISTINCT segment, COUNT(product_code) as product_count FROM `dim_product` GROUP by segment ORDER by product_count DESC;

##Q4

WITH cte AS
(SELECT p.segment , 
COUNT(DISTINCT(p.product_code)) AS product_count_2020 
FROM  dim_product p JOIN fact_gross_price fgp 
ON p.product_code = fgp.product_code 
WHERE fgp.fiscal_year = 2020 
GROUP BY p.segment),
cte1 AS 
(SELECT p.segment , 
COUNT(DISTINCT(p.product_code)) AS product_count_2021 
FROM  dim_product p JOIN fact_gross_price fgp 
ON p.product_code = fgp.product_code 
WHERE fgp.fiscal_year = 2021 
GROUP BY p.segment)
SELECT cte.segment , cte.product_count_2020 , cte1.product_count_2021, (cte1.product_count_2021 - cte.product_count_2020) AS difference 
FROM cte JOIN cte1 
ON cte.segment = cte1.segment;



##Q5

SELECT fact_manufacturing_cost.product_code , dim_product.product , ROUND(fact_manufacturing_cost.manufacturing_cost,2) As Cost
FROM fact_manufacturing_cost INNER JOIN dim_product 
ON fact_manufacturing_cost.product_code = dim_product.product_code 
WHERE 
(fact_manufacturing_cost.manufacturing_cost = (select min( manufacturing_cost) from fact_manufacturing_cost)
OR 
fact_manufacturing_cost.manufacturing_cost = (select max( manufacturing_cost) from fact_manufacturing_cost));

##Q6 

SELECT dim_customer.customer_code , dim_customer.customer , ROUND(fact_pre_invoice_deductions.pre_invoice_discount_pct,2) 
AS average_discount_percentage
FROM dim_customer INNER JOIN fact_pre_invoice_deductions 
ON 
dim_customer.customer_code = fact_pre_invoice_deductions.customer_code WHERE 
fact_pre_invoice_deductions.fiscal_year = 2021
and dim_customer.market = 'India'
ORDER BY fact_pre_invoice_deductions.pre_invoice_discount_pct DESC 
LIMIT 5;

##Q7

SELECT MONTH(fact_sales_monthly.date) AS month , 
YEAR(fact_sales_monthly.date) as year , 
ROUND(SUM(fact_gross_price.gross_price * fact_sales_monthly.sold_quantity),2)AS 'Gross sales Amount'
FROM dim_customer INNER JOIN fact_sales_monthly 
ON dim_customer.customer_code = fact_sales_monthly.customer_code 
INNER JOIN fact_gross_price 
ON fact_gross_price.product_code = fact_sales_monthly.product_code 
AND fact_gross_price.fiscal_year = fact_sales_monthly.fiscal_year 
WHERE dim_customer.customer = 'Atliq Exclusive' 
GROUP BY month,year 
ORDER BY year

##Q8

SELECT
CASE
  when month(date) in (9,10,11) then 'Quarter1' 
  when month(date) in (12,1,2) then 'Quarter2'
  when month(date) in (3,4,5) then 'Quarter3'
  when month(date) in (6,7,8) then 'Quarter4'
END as Quarter_2020 ,
SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly 
WHERE fiscal_year = 2020
GROUP BY Quarter; 


##Q9

WITH MYDATA AS
(SELECT c.channel , 
SUM(fgp.gross_price * fsm.sold_quantity)/1000000 AS 'gross_sales_mln'
FROM  dim_customer c INNER JOIN fact_sales_monthly fsm 
ON c.customer_code = fsm.customer_code 
INNER JOIN fact_gross_price fgp 
ON fgp.product_code = fsm.product_code
WHERE fsm.fiscal_year = '2021'
GROUP BY c.channel)

SELECT * , (gross_sales_mln * 100)/SUM(gross_sales_mln) OVER() AS Percentage FROM MYDATA;

##Q10

WITH A as (
    SELECT p.division, p.product, p.product_code, SUM(s.sold_quantity) AS Total_sold_quantity
    FROM dim_product p 
    JOIN fact_sales_monthly s ON p.product_code = s.product_code 
    WHERE s.fiscal_year = 2021 
    GROUP BY p.division, p.product, p.product_code
), B AS (
    SELECT *, DENSE_RANK() OVER (PARTITION BY division ORDER BY Total_sold_quantity DESC) AS Rank_order 
    FROM A
) 
SELECT * 
FROM B 
WHERE Rank_order <= 3;

