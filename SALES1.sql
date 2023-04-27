-- Inspecting Data 
SELECT *
FROM [SQLPROJECTS].[dbo].[SalesSample]

-- Checking unique values

Select Distinct(status) FROM [SQLPROJECTS].[dbo].[SalesSample] -- Nice one to visualize
Select Distinct(YEAR_ID) FROM [SQLPROJECTS].[dbo].[SalesSample] 
Select Distinct(productline) FROM [SQLPROJECTS].[dbo].[SalesSample] -- Nice one to visualize
Select Distinct(COUNTRY) FROM [SQLPROJECTS].[dbo].[SalesSample] -- Nice one to visualize
Select Distinct(DEALSIZE) FROM [SQLPROJECTS].[dbo].[SalesSample] -- Nice one to visualize
Select Distinct(TERRITORY) FROM [SQLPROJECTS].[dbo].[SalesSample]-- Nice one to visualize

-- ANALYSIS
--- Let's start by grouping sales by products line

SELECT PRODUCTLINE, Sum(sales) Revenue
FROM [SQLPROJECTS].[dbo].[SalesSample]
Group by PRODUCTLINE
Order by 2 DESC
--Classic Cars, Vintage Cars 

SELECT YEAR_ID, Sum(sales) Revenue
FROM [SQLPROJECTS].[dbo].[SalesSample]
Group by YEAR_ID
Order by 2 DESC
-- 2005 was a bad year why ? 
--Select Distinct(MONTH_ID) FROM [SQLPROJECTS].[dbo].[SalesSample]  Where YEAR_ID=2005
-- They only operated for 5 months in 2005.

SELECT DEALSIZE, Sum(sales) Revenue
FROM [SQLPROJECTS].[dbo].[SalesSample]
Group by DEALSIZE
Order by 2 DESC
-- Medium , Small, Large

-- What was the best month for sale in a specific year ? How much was earned that month ? 

SELECT YEAR_ID, MONTH_ID ,Sum(sales) Revenue
FROM [SQLPROJECTS].[dbo].[SalesSample]
Where YEAR_ID=2005 or YEAR_ID=2004 or YEAR_ID=2003
Group by YEAR_ID, MONTH_ID
Order by 3 DESC

-- OR

SELECT MONTH_ID ,Sum(sales) Revenue , Count(Ordernumber) Frequency
FROM [SQLPROJECTS].[dbo].[SalesSample]
Where  YEAR_ID=2004
Group by YEAR_ID, MONTH_ID
Order by 2 DESC


-- November seems to be the month that generates the max revenue ? what products are they selling in november ? 

SELECT MONTH_ID ,Sum(sales) Revenue ,Count(Ordernumber) Frequency, PRODUCTLINE
FROM [SQLPROJECTS].[dbo].[SalesSample]
Where Year_id=2003 and  MONTH_ID=11 --change year to see 
Group by Month_id,PRODUCTLINE
Order by 2 DESC

-- Who is our best customer ? Using RFM ( we have a historical dataset, Indexing and segmenting customers ) F: Frequency: How often they purchase ?
-- R: Recency = How long ago their last purchase was ?
-- M: Monetary value = How much they spent ? 

-- R : Last Order Date F: Total Orders M: Total Spent

SELECT *
FROM [SQLPROJECTS].[dbo].[SalesSample]

DROP TABLE IF EXISTS #RFM

;WITH RFM
AS
(
		SELECT 
			CUSTOMERNAME, 
			SUM(sales) MonetaryValue,
			Avg(sales) AvgMonetaryValue,
			Count(ordernumber) Frequency,
			Max(Orderdate) LastOrderDate,
			(Select Max(Orderdate) From [SQLPROJECTS].[dbo].[SalesSample]) MaxOrderDate,
			Datediff(DD,Max(Orderdate),(Select Max(Orderdate) From [SQLPROJECTS].[dbo].[SalesSample]) ) Recency
		FROM [SQLPROJECTS].[dbo].[SalesSample]
		Group By CUSTOMERNAME
),
RFM_CALC As
(
	Select r.*,
	NTILE(4) Over (Order by Recency DESC ) Rfm_Recency, -- 4 for customers with closest order date to max order date
	NTILE(4) Over (Order by Frequency  ) Rfm_Frequency, -- 4 for customers who purchase often
	NTILE(4) Over (Order by MonetaryValue) Rfm_MonetaryValue -- 4 for customers with big purchases
	From RFM R
)
Select  C.*, Rfm_Recency+Rfm_MonetaryValue+Rfm_Frequency As RFMCELL, 
Cast(Rfm_Recency As Varchar) +Cast(Rfm_Frequency As Varchar) + Cast (Rfm_MonetaryValue As Varchar) rfmstring

Into #RFM
from RFM_CALC C

Select Customername, rfm_Recency,rfm_Frequency, rfm_MonetaryValue,
	CASE 
		WHEN rfmstring in  (444,433,443,434) then 'Loyal'
		WHEN rfmstring in (333,331,322,332,423) then 'Active'
		WHEN rfmstring in (344,343,342,341,334,221,222) then 'PotentialChurners'
		WHEN rfmstring in (441,442,411,412,413,414,422,421,424,311) then 'NewCustomers'
		WHEN rfmstring in (244,243,242,241,234,233,232,231,144) then 'Slipping'
		WHEN rfmstring in (111,112,113,114,121,122,123,124,131,132,133,134,211,212,223) then 'Lost'
	END RFM_SEGMENT

From #rfm


--What products are most often sold together? 


