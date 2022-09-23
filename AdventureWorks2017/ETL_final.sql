-- Versão 3 --

-- IMPORTANTE --
-- Este trecho de código aproveita as views criadas na versão 2 deste projeto

-- Tabela fato
SELECT SalesOrderDetailID, ProductID, f.CustomerID, StoreID, ShipMethodID, SpecialOfferID, DueDate, 
OrderQty, UnitPrice, LineTotal, ProductStandardCost, ProfitPerUnity, CustoTaxa, CustoFrete
FROM fVendas f
JOIN sales.Customer s ON f.CustomerID = s.CustomerID

-- Dimensão Produto: vamos remodelar com base no ProductID
-- Eliminando a redundancia de production.product
-- Dimensão Product
SELECT ProductID, ProductSubcategoryID, Name AS ProductName, Color AS ProductColor
FROM Production.Product 
WHERE productid IN (SELECT DISTINCT productid FROM fVendas)

-- Aqui temos algumas redundâncias mas não faz mal, são só 37 linhas
-- ddProductSubcategory
SELECT ProductSubcategoryID, pps.Name AS ProductSubcategory, ppc.Name AS ProductCategory
FROM Production.ProductSubcategory as pps
JOIN
Production.ProductCategory as ppc
ON pps.ProductCategoryID = ppc.ProductCategoryID

-- Dimensão Customer
-- Vamos dar um join no person e depois criamos as dimensões emailpromotion e persontype no PBI
SELECT CustomerID, (FirstName + ' ' + LastName) AS Cliente, TerritoryID, PersonType, EmailPromotion
FROM sales.Customer s
JOIN Person.Person p
ON s.PersonID = p.BusinessEntityID
WHERE CustomerID IN (SELECT DISTINCT CustomerID FROM fVendas)

-- ddTerritory
SELECT TerritoryID, CountryRegionCode, [Group]
FROM sales.SalesTerritory

-- Aglutinando o nome dos vendedores e renomeando as colunas
-- dStore
SELECT SF.BusinessEntityID AS StoreID,Name AS StoreName, SalesPersonID
FROM StoreFiltrada SF
JOIN person.person PP
ON SF.SalesPersonID = PP.BusinessEntityID

-- ddVendedor
SELECT DISTINCT SalesPersonID, (FirstName + ' ' + LastName) AS Vendedor
FROM StoreFiltrada SF
JOIN person.person PP
ON SF.SalesPersonID = PP.BusinessEntityID
-------------------------------------------------------------
-- dSpecialOffer
SELECT SpecialOfferID, Type
FROM sales.SpecialOffer

-- Após isto, foram salvas todas estas consultas como arquivos CSV, juntamos em um só arquivo excel, na qual cada sheet (planilha) fora inserido um arquivo CSV
-- Todos os CSV extraídos do banco de dados estão zipados no arquivo 'sales_csvs_v3.rar' e a planilha foi salva como 'fVendas_final.xlsx'
-- Os demais tratamentos e modelagem de dados podem ser observados no editor Power Query no arquivo 'sales_final.pbix'

