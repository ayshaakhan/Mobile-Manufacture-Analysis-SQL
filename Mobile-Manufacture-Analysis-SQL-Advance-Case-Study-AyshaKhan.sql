--SQL Advance Case Study


--Q1.List all the states in which we have customers who have bought cellphones from 2005 till today.
--BEGIN 
 
	SELECT State from DIM_LOCATION as L 
	INNER JOIN FACT_TRANSACTIONS as F  
	ON F.IDLocation = L.IDLocation
	WHERE YEAR(F.Date) >= 2005 
	GROUP BY L.State;


--END

--Q2.What state in the US is buying the most 'Samsung' cell phones?
--BEGIN
	

	SELECT State 
	FROM (
	SELECT Top 1 L.State,SUM(F.Quantity) as TOTAL_QTY 
	FROM FACT_TRANSACTIONS as F 

		INNER JOIN DIM_LOCATION as L on F.IDLocation = L.IDLocation
		INNER JOIN DIM_MODEL as M on M.IDModel = F.IDModel
		INNER JOIN DIM_MANUFACTURER as MA on MA.IDManufacturer = M.IDManufacturer

	WHERE MA.Manufacturer_Name='Samsung' and L.Country='US'
	GROUP BY L.State
	ORDER BY TOTAL_QTY DESC) as T1;

--END

--Q3.Show the number of transactions for each model per zip code per state.
--BEGIN      

	SELECT MODEL_NAME,STATE,ZIPCODE,
		COUNT(QUANTITY) AS NUM_OF_TRANS
			FROM DIM_LOCATION AS L

				INNER JOIN FACT_TRANSACTIONS AS F
				ON L.IDLocation = F.IDLocation

				INNER JOIN DIM_MODEL AS M
				ON F.IDModel = M.IDModel

	GROUP BY Model_Name, ZipCode, STATE

--END

--Q4.  Show the cheapest cellphone (Output should contain the price also)
--BEGIN	

     SELECT TOP 1 Model_Name, Unit_price
	   FROM DIM_MODEL
	     ORDER BY Unit_price 

--END

--Q5. Find out the average price for each model in the top5 manufacturers in terms of sales quantity and order by average price.
--BEGIN

	SELECT TOP 5  M.IDManufacturer, M.IDModel,
	SUM(QUANTITY) AS TOTAL_QTY,
	AVG(Unit_price) AS AVG_PRICE 
	FROM DIM_MODEL AS M

	LEFT JOIN FACT_TRANSACTIONS AS F
	ON M.IDModel = F.IDModel             
	
	GROUP BY M.IDModel, M.IDManufacturer
	ORDER BY TOTAL_QTY DESC , AVG_PRICE DESC
	         
--END

--Q6.List the names of the customers and the average amount spent in 2009, where the average is higher than 500
--BEGIN

	SELECT Customer_Name, AVG_AMT, YEAR
	FROM DIM_CUSTOMER AS C
	INNER JOIN (
				SELECT
				AVG(TotalPrice) AS AVG_AMT, YEAR, IDCustomer
				FROM FACT_TRANSACTIONS AS T1

				INNER JOIN DIM_DATE AS T2
				ON T1.Date = T2.DATE

				WHERE YEAR = 2009
				GROUP BY YEAR, IDCustomer
				HAVING AVG(TotalPrice) > 500
				) AS D
	ON C.IDCustomer = D.IDCustomer

--END
	
--Q7.List if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008, 2009 and 2010
--BEGIN  

		SELECT * FROM (SELECT TOP 5 IDModel 
			FROM FACT_TRANSACTIONS
			WHERE YEAR(Date) = '2008'
			GROUP BY IDModel , YEAR(DATE)
			ORDER BY SUM(Quantity) DESC) AS X

			   INTERSECT

		SELECT * FROM (SELECT TOP 5 IDModel
			FROM FACT_TRANSACTIONS
			WHERE YEAR(Date) = '2009'
			GROUP BY IDModel,  YEAR(DATE)
			ORDER BY SUM(Quantity) DESC) AS Y
			   
			   INTERSECT

		 SELECT * FROM (SELECT TOP 5 IDModel 
			FROM FACT_TRANSACTIONS
			WHERE YEAR(Date) = '2010'
			GROUP BY IDModel, YEAR(DATE) 
			ORDER BY SUM(Quantity) DESC) AS Z

--END

--Q8. Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer with the 2nd top sales in the year of 2010.
--BEGIN
 
	SELECT * 
	FROM (SELECT TOP 1
			Manufacturer_Name,B.IDManufacturer,[YEAR], SUM_OF_SALES
			FROM DIM_MANUFACTURER AS A

	INNER JOIN  (       SELECT TOP 2 IDManufacturer,
						YEAR(DATE) AS [YEAR],
						SUM(TotalPrice) AS SUM_OF_SALES
						FROM FACT_TRANSACTIONS AS T1

	INNER JOIN          DIM_MODEL AS T2
						ON T1.IDModel = T2.IDModel
						WHERE YEAR(Date) = 2009
						GROUP BY  IDManufacturer, YEAR(DATE)) AS B
            
			ON A.IDManufacturer = B.IDManufacturer
			ORDER BY SUM_OF_SALES 
				
	UNION ALL                                      
			
			SELECT TOP 1 Manufacturer_Name,D.IDManufacturer, [YEAR], SUM_SALES
			FROM DIM_MANUFACTURER AS C
			
	INNER JOIN         (SELECT TOP 2 IDManufacturer,
						YEAR(DATE) AS [YEAR],
						SUM(TotalPrice) AS SUM_SALES
						FROM FACT_TRANSACTIONS AS T1

	INNER JOIN          DIM_MODEL AS T2
						ON T1.IDModel = T2.IDModel
						WHERE YEAR(Date) = 2010
						GROUP BY  IDManufacturer, YEAR(DATE)
						ORDER BY SUM_SALES DESC) AS D

            ON C.IDManufacturer = D.IDManufacturer  
			ORDER BY SUM_SALES ASC
	  ) AS Y

--END

--Q9.Show the manufacturers that sold cellphones in 2010 but did not in 2009.
--BEGIN

	SELECT Manufacturer_Name, Z.IDManufacturer
	FROM DIM_MANUFACTURER AS Y
	INNER JOIN	(SELECT IDManufacturer
				FROM DIM_MODEL AS T1
				INNER JOIN FACT_TRANSACTIONS AS T2
				ON T1.IDModel = T2.IDModel
				WHERE YEAR(Date) = 2010 ) AS Z
	ON Y.IDManufacturer = Z.IDManufacturer
	
	EXCEPT
				 				   
	SELECT Manufacturer_Name, Z.IDManufacturer
	FROM DIM_MANUFACTURER AS Y
	INNER JOIN	(SELECT IDManufacturer
				FROM DIM_MODEL AS T1
				INNER JOIN FACT_TRANSACTIONS AS T2
				ON T1.IDModel = T2.IDModel
				WHERE YEAR(Date) = 2009) AS Z
	ON Y.IDManufacturer = Z.IDManufacturer

--END

--Q10. Find top 100 customers and their average spend, average quantity by each year. Also find the percentage of change in their spend.
--BEGIN

	SELECT YEARS,IDCustomer,
	AVG(TotalPrice) AS AVG_SPEND,
	AVG(Quantity) AS AVG_QUANT,
	LAG(AVG(TOTALPRICE),1) OVER ( ORDER BY IDCUSTOMER) AS PREV,
	(AVG(TOTALPRICE) - LAG(AVG(TOTALPRICE),1) OVER ( ORDER BY IDCUSTOMER)) / (LAG(AVG(TOTALPRICE),1) OVER (ORDER BY IDCUSTOMER)) * 100 AS [YOY_CHANGE]
	FROM (
			SELECT TOP 100 IDCustomer,
			YEAR(Date) AS [YEARS],
			TotalPrice,Quantity
			FROM FACT_TRANSACTIONS
			ORDER BY TotalPrice DESC
			) AS X
	GROUP BY IDCustomer, YEARS, TotalPrice

--END
	