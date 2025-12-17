USE AdventureWorks2025

SELECT TOP 5 * FROM Production.ProductCategory
SELECT TOP 5 * FROM Production.ProductSubcategory
SELECT * FROM Production.Product


---------------------------------------------------------------------------------------
--1: Antal produkter per kategori
--Affärsfråga: Hur många produkter finns i varje kategori?
---------------------------------------------------------------------------------------

SELECT 
    COALESCE (pc.Name, 'Saknar kategori') AS Kategori,
    COUNT(p.ProductID) AS AntalProdukter
FROM 
    Production.Product p
LEFT JOIN Production.ProductSubcategory ps 
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
LEFT JOIN Production.ProductCategory pc 
    ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY 
    COALESCE(pc.Name, 'Saknar kategori')
ORDER BY 
    CASE WHEN COALESCE(pc.Name, 'Saknar kategori') = 'Saknar kategori' THEN 1 ELSE 0 END,
    AntalProdukter DESC;


-------------------------------------------------------------------------------------
--2: Försäljning per produktkategori
--Affärsfråga: Vilka produktkategorier genererar mest intäkter?
-------------------------------------------------------------------------------------

SELECT TOP 5 * FROM Production.ProductCategory
SELECT TOP 5 * FROM Production.ProductSubcategory
SELECT * FROM Production.Product
SELECT TOP 30 * FROM Sales.SalesOrderDetail WHERE UnitPriceDiscount > 0
SELECT COUNT(*) AS AntalRader FROM Sales.SalesOrderDetail

--Kontrollera totalsumma
SELECT SUM(LineTotal) AS TotalLineTotal
FROM Sales.SalesOrderDetail;

--Kontrollera om någon rad saknar kategori --> ingen rad saknar kategori
SELECT COUNT(*) AS OrderraderMedSaknadKategori
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
LEFT JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
LEFT JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE pc.ProductCategoryID IS NULL;

--Lägg in i ipynb
SELECT 
    COALESCE (pc.Name, 'Saknar kategori') AS Kategori,
    SUM(LineTotal) AS SummaKategori
FROM 
    Sales.SalesOrderDetail sod
INNER JOIN Production.Product p
    ON sod.ProductID = p.ProductID
LEFT JOIN Production.ProductSubcategory ps 
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
LEFT JOIN Production.ProductCategory pc 
    ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY 
    COALESCE(pc.Name, 'Saknar kategori')
ORDER BY 
    CASE WHEN COALESCE(pc.Name, 'Saknar kategori') = 'Saknar kategori' THEN 1 ELSE 0 END,
    SummaKategori DESC;

-- För att förstå vilken valuta
SELECT TOP 5 * FROM Sales.SalesOrderHeader
SELECT * FROM Sales.CurrencyRate

SELECT DISTINCT ToCurrencyCode
FROM Sales.CurrencyRate
WHERE ToCurrencyCode = 'USD';


------------------------------------------------------------------------------------
--3: Försäljningstrend över tid
--Affärsfråga: Hur har försäljningen utvecklats över tid?
------------------------------------------------------------------------------------

--Kolla data i tabellen
SELECT TOP 100 * FROM Sales.SalesOrderHeader

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
    SUM(TotalDue) AS TotalForsaljning,
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
SELECT SUM(TotalDue) AS TotalSumma
FROM Sales.SalesOrderHeader;

SELECT SUM(MonthSum) AS TotalViaManader
FROM (
    SELECT
        YEAR(OrderDate) AS OrderYear,
        MONTH(OrderDate) AS OrderMonth,
        SUM(TotalDue) AS MonthSum
    FROM Sales.SalesOrderHeader
    GROUP BY
        YEAR(OrderDate),
        MONTH(OrderDate)
) t;

--Kontrollera vilka månader som ej är fullständiga 
WITH MonthlySales AS (
    SELECT
        DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS OrderMonth,
        SUM(TotalDue) AS TotalForsaljning,
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


------------------------------------------------------------------------------
--4: Försäljning och antal ordrar per år
--Affärsfråga: Hur ser total försäljning och antal ordrar ut per år?
-----------------------------------------------------------------------------


--Lägga in i ipynb
-- (1. Rådata till månadsnivå, 2. månadsnivå till årsnivå, 3. visualisera.)
WITH Monthly AS (
    SELECT
        DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS OrderMonth,
        YEAR(OrderDate) AS OrderYear,
        SUM(TotalDue) AS TotalForsaljning,
        COUNT(*) AS AntalOrdrar,
        CASE
            WHEN MIN(CAST(OrderDate AS date)) = DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
             AND MAX(CAST(OrderDate AS date)) = EOMONTH(DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1))
            THEN 1 ELSE 0
        END AS IsFullMonth
    FROM Sales.SalesOrderHeader
    GROUP BY DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1), YEAR(OrderDate)
),
Yearly AS (
    SELECT
        OrderYear,

        -- Alla månader (oavsett full/inte)
        SUM(TotalForsaljning) AS TotalForsaljning_All,
        SUM(AntalOrdrar)      AS AntalOrdrar_All,
        COUNT(*)              AS Manader_All,

        -- Endast fulla månader
        SUM(CASE WHEN IsFullMonth = 1 THEN TotalForsaljning ELSE 0 END) AS TotalForsaljning_Full,
        SUM(CASE WHEN IsFullMonth = 1 THEN AntalOrdrar      ELSE 0 END) AS AntalOrdrar_Full,
        SUM(IsFullMonth) AS Manader_Full
    FROM Monthly
    GROUP BY OrderYear
)
SELECT *
FROM Yearly
ORDER BY OrderYear;

--Kontroller
SELECT COUNT(*) AS AntalRader
FROM Sales.SalesOrderHeader;

-----------------------------------------------------------------------------------
--5:  Top 10 produkter
--Affärsfråga: Vilka 10 produkter genererar mest försäljning?
----------------------------------------------------------------------------------

--Lägga in i ipynb
SELECT TOP 10
    SUM(sod.LineTotal) AS TotalForsaljningPerProdukt,
    p.Name AS Produkt,
    pc.Name AS Kategori,
    AVG(sod.UnitPrice) AS MedelPris_perorderrad,
    SUM(sod.UnitPrice * sod.OrderQty) / NULLIF(SUM(sod.OrderQty), 0) AS MedelPris_vagt --Utan discount
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
LEFT JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
LEFT JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY p.Name, pc.Name
ORDER BY SUM(sod.LineTotal) DESC;

--Kontroll
SELECT
    p.Name,
    SUM(sod.LineTotal) AS TotalForsaljningPerProdukt
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p 
    ON sod.ProductID = p.ProductID
GROUP BY p.Name
ORDER BY TotalForsaljningPerProdukt DESC;

SELECT
    p.Name,
    sod.SalesOrderID,
    sod.LineTotal
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p 
    ON sod.ProductID = p.ProductID
WHERE p.Name = 'Mountain-200 Black, 38'
ORDER BY sod.LineTotal DESC;

SELECT * FROM Sales.SalesOrderDetail sod
JOIN Production.Product p 
    ON sod.ProductID = p.ProductID
WHERE sod.SalesOrderID= 53573 AND p.Name = 'Mountain-200 Black, 38'


SELECT
    p.Name,
    sod.SalesOrderID,
    sod.OrderQty,
    sod.UnitPrice,
    sod.LineTotal
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p 
    ON sod.ProductID = p.ProductID
WHERE p.Name = 'Mountain-200 Black, 38'
ORDER BY sod.UnitPrice DESC;

--Förstå UnitPrice, för att förstå tolkning av total försäljning. 

SELECT
    sod.UnitPrice,
    SUM(sod.OrderQty) AS TotalAntal,
    COUNT(*) AS AntalOrderrader
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p 
    ON sod.ProductID = p.ProductID
WHERE p.Name = 'Mountain-200 Black, 38'
GROUP BY sod.UnitPrice
ORDER BY sod.UnitPrice DESC;


-------------------------------------------------------------------------
--6. Försäljning och antal kunder per region
-- Affärsfråga: Hur skiljer sig försäljningen mellan olika regioner, och hur många unika kunder har varje region?

