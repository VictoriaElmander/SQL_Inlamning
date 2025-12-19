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
        SUM(SubTotal) AS TotalForsaljning,
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


-----------------------------------------------------------------------------------------------------------------
--6. Försäljning och antal kunder per region
-- Affärsfråga: Hur skiljer sig försäljningen mellan olika regioner, och hur många unika kunder har varje region?
------------------------------------------------------------------------------------------------------------------

SELECT TOP 50 * FROM Sales.Customer
SELECT TOP 3 * FROM Sales.SalesOrderHeader
SELECT TOP 20 * FROM Sales.SalesTerritory


--Lägga in i ipynb
SELECT
    CONCAT(st.CountryRegionCode,'-', st.Name) AS Region,
    COALESCE(SUM(soh.SubTotal), 0) AS TotalForsaljningRegion,
    COUNT(DISTINCT c.CustomerID) AS UnikaKunderTotalt,
    COUNT(DISTINCT soh.CustomerID) AS UnikaKunderMedOrder,
    COUNT(soh.SalesOrderID) AS AntalOrdrar
FROM Sales.SalesTerritory st
LEFT JOIN Sales.Customer c
    ON c.TerritoryID = st.TerritoryID
LEFT JOIN Sales.SalesOrderHeader soh
    ON soh.CustomerID = c.CustomerID
GROUP BY st.CountryRegionCode, st.Name
ORDER BY TotalForsaljningRegion DESC;


--Kollar antal ordrar per kund
SELECT
    CustomerID,
    COUNT(*) AS AntalOrdrar
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
HAVING COUNT(*) > 1
ORDER BY AntalOrdrar DESC;


-------------------------------------------------------------------------
--7. Genomsnittligt ordervärde per region och kundtyp
-- Affärsfråga: Vilka regioner har högst/lägst genomsnittligt ordervärde, 
--och skiljer det sig mellan individuella kunder och företagskunder?
-------------------------------------------------------------------------
SELECT TOP 20 * FROM Sales.Store
SELECT TOP 2 * FROM Sales.Customer
SELECT TOP 100 * FROM Sales.SalesTerritory
SELECT TOP 100 * FROM Sales.SalesOrderHeader 


--Lägga in i ipynb
WITH Base AS (
    SELECT
        CONCAT(st.CountryRegionCode,'-', st.Name) AS Region,
        CASE
            WHEN c.StoreID IS NOT NULL THEN 'Företagskund'
            WHEN c.PersonID IS NOT NULL THEN 'Privatkund'
            ELSE 'Okänd'
        END AS Kundtyp,
        soh.SubTotal,
        soh.SalesOrderID
    FROM Sales.SalesOrderHeader soh
    JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
    JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
),
Agg AS (
    SELECT
        Region,
        Kundtyp,
        SUM(SubTotal) AS TotalForsaljning,
        COUNT(*) AS AntalOrdrar,
        --1.0 gör så att det blir flyttalsdivision
        SUM(SubTotal) * 1.0 / NULLIF(COUNT(*), 0) AS AOV_Kundtyp 
    FROM Base
    GROUP BY Region, Kundtyp
),
RegionTotal AS (
    SELECT
        Region,
        SUM(TotalForsaljning) * 1.0 / NULLIF(SUM(AntalOrdrar), 0) AS AOV_Totalt
    FROM Agg
    GROUP BY Region
)
SELECT
    a.Region,
    a.Kundtyp,
    a.AOV_Kundtyp,
    rt.AOV_Totalt
FROM Agg a
JOIN RegionTotal rt ON a.Region = rt.Region
ORDER BY rt.AOV_Totalt DESC, a.Region, a.Kundtyp;


---------------------------------------------------------------------
--DJUPANALYS: ALTERNATIV A: Regional försäljningsoptimering
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Vilken region presterar bäst/sämst?
---------------------------------------------------------------------
WITH Monthly AS (
    SELECT
        CONCAT(st.CountryRegionCode,'-', st.Name) AS Region,
        DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS OrderMonth,
        YEAR(OrderDate) AS OrderYear,
        SUM(SubTotal) AS TotalForsaljning
        --COUNT(*) AS AntalOrdrar,
        --CASE
            --WHEN MIN(CAST(OrderDate AS date)) = DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
             --AND MAX(CAST(OrderDate AS date)) = EOMONTH(DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1))
            --THEN 1 ELSE 0
        --END AS IsFullMonth
    FROM Sales.SalesOrderHeader soh
    JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
    GROUP BY 
        CONCAT(st.CountryRegionCode,'-', st.Name),
        DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1), 
        YEAR(OrderDate) 
),
MonthlyFlag AS (
    SELECT
        m.*,
        CASE
            WHEN m.OrderMonth > MIN(m.OrderMonth) OVER ()
             AND m.OrderMonth < MAX(m.OrderMonth) OVER ()
            THEN 1 ELSE 0
        END AS IsFullMonth
    FROM Monthly m
),
Yearly AS (
    SELECT
        Region,
        OrderYear,

        -- Alla månader (oavsett full/inte)
        SUM(TotalForsaljning) AS TotalForsaljning_All,
        --SUM(AntalOrdrar) AS AntalOrdrar_All,
        COUNT(*) AS Manader_All,

        -- Endast fulla månader
        SUM(CASE WHEN IsFullMonth = 1 THEN TotalForsaljning ELSE 0 END) AS TotalForsaljning_Full,
        --SUM(CASE WHEN IsFullMonth = 1 THEN AntalOrdrar      ELSE 0 END) AS AntalOrdrar_Full,
        SUM(IsFullMonth) AS Manader_Full
    FROM MonthlyFlag
    GROUP BY Region, OrderYear
)
SELECT *
FROM Yearly
ORDER BY Region, OrderYear;


---------------------------------------------------------------------
-- Vilka produktkategorier säljer bäst var?
---------------------------------------------------------------------
WITH Base AS (
    SELECT 
        CONCAT(st.CountryRegionCode,'-', st.Name) AS Region, 
        COALESCE(pc.Name, 'Saknar kategori') AS Kategori,
        SUM(sod.LineTotal) AS SummaKategori
    FROM Sales.SalesOrderDetail sod
    INNER JOIN Production.Product p
        ON sod.ProductID = p.ProductID
    LEFT JOIN Production.ProductSubcategory ps 
        ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    LEFT JOIN Production.ProductCategory pc 
        ON ps.ProductCategoryID = pc.ProductCategoryID
    INNER JOIN Sales.SalesOrderHeader soh 
        ON sod.SalesOrderID = soh.SalesOrderID
    INNER JOIN Sales.SalesTerritory st
        ON soh.TerritoryID = st.TerritoryID
    GROUP BY 
        CONCAT(st.CountryRegionCode,'-', st.Name),
        COALESCE(pc.Name, 'Saknar kategori')
),
WithTotals AS (
    SELECT *,
        SUM(SummaKategori) OVER (PARTITION BY Region)   AS RegionTotal,
        SUM(SummaKategori) OVER (PARTITION BY Kategori) AS KategoriTotal
    FROM Base
)
SELECT *
FROM WithTotals
ORDER BY
    RegionTotal DESC,
    KategoriTotal DESC;


---------------------------------------------------------------------
-- Finns säsongsmönster per region?
---------------------------------------------------------------------
WITH Monthly AS (
    SELECT
        CONCAT(st.CountryRegionCode, '-', st.Name) AS Region,
        DATEFROMPARTS(YEAR(soh.OrderDate), MONTH(soh.OrderDate), 1) AS OrderMonth,
        YEAR(soh.OrderDate)  AS OrderYear,
        MONTH(soh.OrderDate) AS OrderMonthNum,
        SUM(soh.SubTotal) AS TotalForsaljning
    FROM Sales.SalesOrderHeader soh
    JOIN Sales.SalesTerritory st
        ON soh.TerritoryID = st.TerritoryID
    GROUP BY
        CONCAT(st.CountryRegionCode, '-', st.Name),
        DATEFROMPARTS(YEAR(soh.OrderDate), MONTH(soh.OrderDate), 1),
        YEAR(soh.OrderDate),
        MONTH(soh.OrderDate)
)
SELECT *
FROM Monthly
-- Ta bort första och sista månaden, då vi sedan tidigare vet att de är ofullständiga
WHERE OrderMonth > (SELECT MIN(OrderMonth) FROM Monthly)
  AND OrderMonth < (SELECT MAX(OrderMonth) FROM Monthly)
ORDER BY Region, OrderYear, OrderMonthNum;  