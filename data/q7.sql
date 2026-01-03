USE AdventureWorks2025

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