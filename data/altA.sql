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