USE AdventureWorks2025

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