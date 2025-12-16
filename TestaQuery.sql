USE AdventureWorks2025

SELECT TOP 5 * FROM Production.ProductCategory
SELECT TOP 5 * FROM Production.ProductSubcategory
SELECT * FROM Production.Product

--1: Antal produkter per kategori
--Affärsfråga: Hur många produkter finns i varje kategori?
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

--2: Försäljning per produktkategori
--Affärsfråga: Vilka produktkategorier genererar mest intäkter?

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


--3: Försäljningstrend över tid
--Affärsfråga: Hur har försäljningen utvecklats över tid?
SELECT TOP 100 * FROM Sales.SalesOrderHeader

--Lägg in i ipynb
SELECT 
    DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS OrderMonth,
    SUM(TotalDue) AS TotalForsaljning
FROM 
    Sales.SalesOrderHeader
GROUP BY 
    DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
ORDER BY 
    OrderMonth;

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