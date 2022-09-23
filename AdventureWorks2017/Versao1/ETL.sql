-- Versão 1 –-

-- Modelagem da tabela Fato

-- Nossa tabela fato será a SalesOrderDetail
SELECT SalesOrderDetailID, SalesOrderID, ProductID, SpecialOfferID, CarrierTrackingNumber, OrderQty, UnitPrice, UnitPriceDiscount, LineTotal
FROM sales.SalesOrderDetail

-- Modelagem das dimensões

-- Chamei de 1 ramo as dimensões primárias da tabela fato, 2 ramo as dimensões secundárias e assim por diante. Mais adiante eu passo a chamar

-- 1 ramo
SELECT SpecialOfferID, Description, DiscountPct, Type, Category, MinQty, MaxQty, StartDate,EndDate
FROM sales.SpecialOffer

-- 1 ramo
SELECT ProductID, ProductSubcategoryID, Name, MakeFlag, FinishedGoodsFlag, Color, SafetyStockLevel, ReorderPoint, StandardCost, ListPrice, Size, SizeUnitMeasureCode, WeightUnitMeasureCode, Weight,
DaysToManufacture, ProductLine, Class, Style, SellStartDate, SellEndDate
FROM Production.Product


-- 2 ramo
SELECT ProductSubcategoryID, ProductCategoryID, Name
FROM Production.ProductSubcategory

-- 3 ramo
SELECT ProductCategoryID, Name
FROM Production.ProductCategory

-- 1 ramo
SELECT SalesOrderID, CustomerID, SalesPersonID, TerritoryID, ShipToAddressID, ShipMethodID, CreditCardID, CurrencyRateID, RevisionNumber, Status, 
OnlineOrderFlag, CreditCardApprovalCode, SubTotal, TaxAmt, Freight, TotalDue, DATEPART(DAY,(shipdate - orderdate)) AS 'ShipDelay', 
DATEPART(DAY,(DueDate - OrderDate)) AS 'DueDelay'
FROM sales.SalesOrderHeader

-- 2 ramo
-- TerritoryID
SELECT TerritoryID, Name, CountryRegionCode, [Group]
FROM sales.SalesTerritory

-- 2 ramo
-- ShipMethodID
SELECT ShipMethodID, Name, ShipBase, ShipRate 
FROM Purchasing.ShipMethod

-- 2 ramo
-- CreditCardID
SELECT CreditCardID, CardType, ExpMonth, ExpYear 
FROM sales.CreditCard

-- 2 ramo
-- CurrencyRateID
SELECT CurrencyRateID, CurrencyRateDate, FromCurrencyCode, ToCurrencyCode, AverageRate
FROM Sales.CurrencyRate

-- 2 ramo
-- CustomerID
SELECT CustomerID, PersonID, StoreID
FROM sales.customer

-- 3 ramo
SELECT BusinessEntityID AS 'PersonID', PersonType, (FirstName + ' ' + LastName) AS 'CompleteName', EmailPromotion
FROM person.Person

-- 3 ramo
SELECT BusinessEntityID AS 'StoreID', Name, SalesPersonID
FROM Sales.Store

-- 4 ramo
SELECT BusinessEntityID AS 'SalesPersonID', SalesQuota, Bonus, CommissionPct, SalesYTD, SalesLastYear
FROM sales.SalesPerson

-- Temos um problema que o PBI não identifica a contagem de lojas por região, vamos tentar fazer um join na mão para resolver isso
SELECT SS.BusinessEntityID, TerritoryID
FROM sales.SalesPerson SSP
JOIN sales.Store SS
on SS.SalesPersonID = SSP.BusinessEntityID

-- Após isto, foram salvas todas estas consultas como arquivos CSV
-- Todos os CSV extraídos do banco de dados estão zipados no arquivo 'sales_csvs_v1.rar'
-- Os demais tratamentos podem ser observados no editor Power Query no arquivo 'SalesV1.pbix'

-- Essa primeira versão apresentou muitos problemas e não teve um resultado satisfatório 
