---Data Analysis---- 

SELECT * from city;
SELECT * from products;
SELECT * from customers;
SELECT * from sales;


--Q1 --cofffee consumers count---
----Query to find the no of people who consume coffee in each city ,assuming 25% of the population does



SELECT 
city_name, 
ROUND(
(population * 025)/1000000,
2)as coffee_consumes_in_millions,
city_rank 
FROM city
ORDER BY 2 DESC


---Q2Total revenue from coffee sales
---What is the total revenue generated from coffee sales accross all cities in the last quater of 2023?

SELECT * FROM sales

SELECT 
ci.city_name,
SUM(total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
on ci.city_id = c.city_id
WHERE 
     EXTRACT(YEAR FROM sale_date) = 2023
	 AND
	 EXTRACT(quarter FROM sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC


--Q3Sales count-----
----How many units of each cofffee product have been sold?

SELECT 
    p.product_name,
	COUNT(s.total) as total_orders
FROM products as p
  LEFT JOIN
  sales as s
  ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC 

---Q4Average sales amount per city----
-----What is the average sales amount per customer in each city 

SELECT 
ci.city_name,
SUM(s.total) as total_revenue, 
COUNT(DISTINCT s.customer_id)as total_cx,
ROUND
(SUM(S.total) :: numeric/COUNT(DISTINCT s.customer_id):: numeric ,2) as avg_sale_percity
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
on ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC



---q5 City population and coffee consumers
---Provide a list of cities along with their poppulation and estimated coffee consumers
--return city_name, total current cx,estimated coffee consumers(25%)

WITH city_table as

(SELECT
       city_name,
       ROUND((population * 0.25)/1000000 ,2) as coffee_consumers
FROM city),

customers_table
as
(SELECT
       ci.city_name,
       COUNT(DISTINCT c.customer_id) as unique_cx
FROM sales as s 
Join customers as c 
ON c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id=c.city_id
GROUP BY 1) 

SELECT
    customers_table.city_name,
	 city_table.coffee_consumers,
	 customers_table.unique_cx
FROM city_table 
JOIN 
customers_table 
on city_table.city_name = customers_table.city_name 


--q6--top selling product by city
--what are the top 3 selling products in the each city base on business sales

SELECT *
FROM --table
(
SELECT 
ci.city_name,
p.product_name,
COUNT(s.sale_id) as total_orders,
DENSE_RANK()OVER(PARTITION BY ci.city_name ORDER BY COUNT (s.sale_id)DESC) as rank
from sales as s
JOIN products as p
on s.product_id = p.product_id
JOIN customers as c
ON c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id= c.city_id 
GROUP BY 1,2 
ORDER BY 1,3 DESC
) as t1
WHERE rank <=3

--q7--customer segmentation by city--
----How many unique customers are there in each city who have purchase the coffee products

SELECT 
	ct.city_name,
	count(distinct s.customer_id) AS Unique_No_Customers,
	count(s.product_id) AS product_count_ordered
FROM sales s
JOIN customers c 
ON s.customer_id = c.customer_id
JOIN city ct 
 ON c.city_id = ct.city_id
GROUP BY 1
ORDER BY 3 DESC, 1;


---q8--------
------Find each city and their average sale per customer and avg cent per customers 

SELECT 
ci.city_name,
SUM(s.total) as total_revenue,
COUNT(DISTINCT s.customer_id) as total_customers,
ROUND(SUM(TOTAL :: numeric/ COUNT(DISTINCT s.customer_id) :: numeric, 2 ),
as average_sales_per_customer,
ROUND(ci.estimated_rent/COUNT(DISTINCT s.customer_id )::numeric,2) as average_rent))
FROM sales as s
JOIN customers as c ON
s.customer_id = c.customer_id
JOIN city as ci ON
ci.city_id = c.city_id
GROUP BY ci.city_name, ci.estimated_rent
ORDER BY 5 DESC


---Q9--Monthly Sales Growth----
----Sales growth rate : Calculate the percentage growth(or decline) in sales over diffferent time periods in each city

WITH
monthly_sales
AS
(
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) as month,
		EXTRACT(YEAR FROM sale_date) as YEAR,
		SUM(s.total) as total_sale
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),
growth_ratio
AS
(
		SELECT
			city_name,
			month,
			year,
			total_sale as cr_month_sale,
			LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
		FROM monthly_sales
)

SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric * 100
		, 2
		) as growth_ratio

FROM growth_ratio
WHERE 
	last_month_sale IS NOT NULL	

	  

-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer



WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
				SUM(s.total)::numeric/
					COUNT(DISTINCT s.customer_id)::numeric
				,2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(SELECT 
	city_name, 
	estimated_rent,
	ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent::numeric/
									ct.total_cx::numeric
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 4 DESC




/*
-- Recomendation
City 1: Pune

Achieved the highest total revenue among all cities.
Maintains a low average rent per customer, ensuring high profitability.
Demonstrates strong customer purchasing power with a high average sale per customer.

City 2:  Delhi

Leads with the highest estimated coffee consumer base (~7.7 million).
Has the largest active customer base (68 customers).
Rent per customer is reasonable at ₹330, supporting sustainable operations.

City 3:  Jaipur

Highest number of unique customers (69), indicating high engagement.
Features the lowest average rent per customer at just ₹156.
Maintains strong average sales (~₹11.6K), reflecting solid individual spending.


