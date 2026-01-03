USE AdventureWorks2025

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

SELECT TOP 5 * FROM Sales.SalesOrderDetail