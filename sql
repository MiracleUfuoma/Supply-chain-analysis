SELECT * FROM [dbo].[supply_chain_data]
--PRODUCTS AND SALES PERFORMANCE ANALYSIS
--Average revenue per unit
SELECT
    "Product_type",
    ROUND(SUM("Revenue_generated") / SUM("Number_of_products_sold"), 2) AS AverageRevenuePerUnit
FROM
    [dbo].[supply_chain_data]
GROUP BY
    "Product_type"
ORDER BY
    AverageRevenuePerUnit DESC

--Average selling price per product type
SELECT
    "Product_type",
    ROUND(AVG("Price"), 2) AS Averagesellingprice
FROM
    [dbo].[supply_chain_data]
GROUP BY
    "Product_type"
ORDER BY
    AverageSellingprice DESC;

--Products with high manufacturing costs
SELECT Product_type, ROUND(SUM(Manufacturing_costs * Production_volumes), 2) AS Totalproductioncost
FROM 
    [dbo].[supply_chain_data]
GROUP BY Product_type
ORDER BY Totalproductioncost DESC

--Product type with highest revenue
SELECT Product_type, ROUND(SUM(Revenue_generated), 2) AS TotalRevenue
FROM 
    [dbo].[supply_chain_data]
GROUP BY
    Product_type
ORDER BY
    TotalRevenue DESC

--Top selling SKUs by quantity and revenue
WITH SKUsales AS (
SELECT SKU, Product_type, 
     ROUND(SUM(Revenue_generated), 2) AS TotalRevenue,
     SUM(Number_of_products_sold) AS TotalUnits
FROM 
    [dbo].[supply_chain_data]
GROUP BY 
    SKU, Product_type),
Ranked_SKU AS (
        SELECT SKU, Product_type, TotalRevenue, TotalUnits,
		RANK() OVER (ORDER BY TotalUnits DESC) AS UnitsRank,
		RANK () OVER (ORDER BY TotalRevenue DESC) AS RevenueRank
	FROM SKUsales)
SELECT *
FROM Ranked_SKU
WHERE UnitsRank <=10
ORDER BY UnitsRank, RevenueRank


--Are cheaper products selling more? Are expensive ones performing poorly?
WITH SKUmetrics AS (
    SELECT SKU,Price,
    SUM(Number_of_products_sold) AS TotalUnits
    FROM 
    [dbo].[supply_chain_data]
    GROUP BY 
    SKU, Price
),
Ranked AS (
SELECT SKU, Price, TotalUnits,
NTILE(4) OVER (ORDER BY TotalUnits DESC) AS demandquartile
FROM SKUmetrics)
SELECT * FROM Ranked

-- Supplier with consistent lead times
WITH Supplierlead AS (
   SELECT 
     supplier_name, 
     AVG(lead_time) AS Avgleadtime,
     STDEV(lead_time) AS Leadtimevariability
FROM 
    [dbo].[supply_chain_data]
GROUP BY Supplier_name)
SELECT *
FROM Supplierlead
ORDER BY Leadtimevariability ASC

--Shipping carriers that deliver the fastest
WITH Fastshipper AS (
   SELECT Shipping_carriers,
   AVG(Shipping_times) AS Avgshippingtime
FROM 
    [dbo].[supply_chain_data]
GROUP BY Shipping_carriers)
SELECT *
FROM Fastshipper
ORDER BY Avgshippingtime ASC 

--Average shipping time by carrier
SELECT Shipping_carriers,
       AVG(Shipping_times) AS Avgshippingtime
FROM 
    [dbo].[supply_chain_data]
GROUP BY Shipping_carriers
ORDER BY Avgshippingtime ASC

--Identifying unreliable suppliers
WITH Supplierlead AS (
   SELECT 
     supplier_name, 
     AVG(lead_time) AS Avgleadtime,
     STDEV(lead_time) AS Leadtimevariability
FROM 
    [dbo].[supply_chain_data]
GROUP BY Supplier_name),

Rankedsuppliers AS (
     SELECT Supplier_name, Avgleadtime, Leadtimevariability,
       RANK() OVER (ORDER BY Avgleadtime DESC) AS Slowest
FROM Supplierlead)

SELECT *
FROM Supplierlead
ORDER BY Leadtimevariability ASC

--Consumer demographic that purchase the most products.
WITH Consumer AS(
SELECT 
   Customer_demographics, 
   SUM (Number_of_products_sold) AS Totalunits,
   SUM (Revenue_generated) AS Totalrevenue
FROM 
    [dbo].[supply_chain_data]
GROUP BY Customer_demographics),
Rankedcustomer AS (
SELECT Customer_demographics,Totalunits, Totalrevenue,
RANK() OVER (ORDER BY Totalunits DESC) AS Unitsrank,
RANK() OVER (ORDER BY Totalrevenue DESC) AS Revenuerank
FROM Consumer)
SELECT *
FROM Rankedcustomer
ORDER BY Unitsrank, Revenuerank

--Location that generates the most revenue
SELECT Location, SUM(Revenue_generated) AS TotalRevenue
FROM 
    [dbo].[supply_chain_data]
GROUP BY Location
ORDER BY TotalRevenue DESC

--Faster transportation modes
WITH mode_shipping AS (
    SELECT
        transportation_modes,
        AVG(Shipping_times) AS avg_shipping_time,
        MIN(Shipping_times) AS fastest_time,
        MAX(Shipping_times) AS slowest_time,
        COUNT(*) AS total_shipments
    FROM  [dbo].[supply_chain_data]
    GROUP BY transportation_modes
)
SELECT *
FROM mode_shipping
ORDER BY avg_shipping_time ASC

--Finding routes that are slow or costly
WITH route_analysis AS (
    SELECT
        Routes,
        AVG(shipping_times) AS avg_shipping_time,
        AVG(shipping_costs) AS avg_shipping_cost,
        COUNT(*) AS total_shipments,
        (AVG(shipping_costs) / NULLIF(AVG(shipping_times),0)) AS cost_per_day
    FROM [dbo].[supply_chain_data]
    GROUP BY Routes
)
SELECT *
FROM route_analysis
ORDER BY cost_per_day DESC, avg_shipping_time ASC
