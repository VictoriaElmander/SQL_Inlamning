USE AdventureWorks2025

------------------------------------------------------------------------------------
--3: Försäljningstrend över tid
--Affärsfråga: Hur har försäljningen utvecklats över tid?
------------------------------------------------------------------------------------

--Kolla data i tabellen
SELECT TOP 100 * FROM Sales.SalesOrderHeader
SELECT TOP 20 * FROM Sales.Currency

SELECT TOP 300 *
FROM Sales.SalesOrderHeader
ORDER BY OrderDate DESC;

SELECT TOP 100 * FROM Sales.SalesOrderDetail

SELECT
  DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS OrderMonth,
  MIN(OrderDate) AS FirstOrderDate,
  MAX(OrderDate) AS LastOrderDate,
  COUNT(*) AS Orders
FROM Sales.SalesOrderHeader
GROUP BY DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
ORDER BY OrderMonth;


--Lägg in i ipynb
SELECT
    DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS OrderMonth,
    SUM(SubTotal) AS TotalForsaljning,
    MIN(CAST(OrderDate AS date)) AS FirstOrderDateInMonth,
    MAX(CAST(OrderDate AS date)) AS LastOrderDateInMonth,
    CASE
        WHEN MIN(CAST(OrderDate AS date)) = DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
         AND MAX(CAST(OrderDate AS date)) = EOMONTH(DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1))
        THEN 1 ELSE 0
    END AS IsFullMonth
FROM Sales.SalesOrderHeader
GROUP BY DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
ORDER BY OrderMonth;

--Kontrollera att summeringen verkar korrekt.
SELECT SUM(SubTotal) AS TotalSumma
FROM Sales.SalesOrderHeader;

SELECT SUM(MonthSum) AS TotalViaManader
FROM (
    SELECT
        YEAR(OrderDate) AS OrderYear,
        MONTH(OrderDate) AS OrderMonth,
        SUM(SubTotal) AS MonthSum
    FROM Sales.SalesOrderHeader
    GROUP BY
        YEAR(OrderDate),
        MONTH(OrderDate)
) t;

--Kontrollera vilka månader som ej är fullständiga 
WITH MonthlySales AS (
    SELECT
        DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS OrderMonth,
        SUM(SubTotal) AS TotalForsaljning,
        MIN(CAST(OrderDate AS date)) AS FirstOrderDateInMonth,
        MAX(CAST(OrderDate AS date)) AS LastOrderDateInMonth,
        CASE
            WHEN MIN(CAST(OrderDate AS date)) = DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
             AND MAX(CAST(OrderDate AS date)) = EOMONTH(DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1))
            THEN 1 ELSE 0
        END AS IsFullMonth
    FROM Sales.SalesOrderHeader
    GROUP BY DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
)
SELECT *
FROM MonthlySales
WHERE IsFullMonth = 0
ORDER BY OrderMonth;