-- Versão 2 –-

-- Aqui já notei que, dado a quantidade de atributos que eu queria inserir nas dimensões, a minha modelagem seria baseada em um SnowFlake Schema

-- Modelagem da tabela Fato
CREATE VIEW [viewSalesOrderDetail] AS
SELECT SalesOrderDetailID, SalesOrderID, SOD.ProductID, SpecialOfferID, ProductSubcategoryID, OrderQty, UnitPrice, LineTotal,
Color AS ProductColor,StandardCost AS ProductStandardCost, (UnitPrice-StandardCost) AS ProfitPerUnity
FROM sales.SalesOrderDetail SOD
-- JOIN Product
JOIN Production.Product PP
ON PP.ProductID = SOD.ProductID

-- Aqui eu queria dar um join e puxar as tabelas Freight e TaxAmt para a tabela SalesOrderDetail, porém não bastava apenas puxar, eu teria que recalcular para cada 
-- ordem de venda detalhada (SalesOrderDetailID) mas eu não tinha uma tabela para saber os custos de frete e taxa em cada caso, então calculei a taxa destes custos em 
-- percentual para cada ordem de venda (SalesOrderID) na tabela SalesOrderHeader e apliquei em cada ordem de venda detalhada, gerando um resíduo o qual desprezei por 
-- ser relativamente pequeno

-- Criando uma view que calcula a taxa percentual do frete e taxamt para cada ordem de venda
CREATE VIEW [Tentativa1] AS
SELECT SalesOrderID, CustomerID, SalesPersonID, TerritoryID, ShipMethodID, SubTotal, TaxAmt, Freight, TotalDue, DueDate, 
(TaxAmt/SubTotal) AS 'Taxa em porcentagem', (Freight/SubTotal) AS 'Taxa de frete'
FROM sales.SalesOrderHeader

-- Criando a Gambiarra (cálculo que vai deixar o resíduo)
CREATE VIEW Gambiarra AS
SELECT viewSalesOrderDetail.SalesOrderDetailID, viewSalesOrderDetail.SalesOrderID, ProductID, SpecialOfferID, ProductSubcategoryID, OrderQty, UnitPrice, LineTotal,
ProductColor,ProductStandardCost, ProfitPerUnity, LineTotal*[Taxa em porcentagem] AS CustoTaxa, LineTotal*[Taxa de frete] AS CustoFrete
FROM [viewSalesOrderDetail]
JOIN
Tentativa1
ON Tentativa1.SalesOrderID = viewSalesOrderDetail.SalesOrderID

-- Criando uma view para auxiliar nos calculos
CREATE VIEW residuo AS
SELECT SalesOrderID, SUM(CustoTaxa) AS Taxa, SUM(CustoFrete) as Frete
FROM Gambiarra
GROUP BY SalesOrderID

-- Verificando o residuo
SELECT SUM(ABS(Taxa-TaxAmt)) AS ResiduoTotalTaxa, SUM(ABS(Frete-Freight)) AS ResiduoTotalFrete
FROM residuo
JOIN
Tentativa1
ON residuo.SalesOrderID = Tentativa1.SalesOrderID

-- Resultado: a gambiarra é relativamente boa, um residuo de 4k para um total de 121k de linhas significa um erro médio de 0,03 por linha

-- Agora criando minha tabela FATO
CREATE VIEW fVendas AS
SELECT 
-- IDS
SalesOrderDetailID, Gambiarra.SalesOrderID - 43658 AS OrderID, ProductID, SpecialOfferID, ProductSubcategoryID, ProductColor, CustomerID, SalesPersonID, TerritoryID, 
ShipMethodID, DueDate, 
-- Atributos
OrderQty, UnitPrice, LineTotal, ProductStandardCost, ProfitPerUnity, CustoTaxa, CustoFrete
FROM Gambiarra
JOIN
Tentativa1 ON Tentativa1.SalesOrderID = Gambiarra.SalesOrderID

-- Resultado
SELECT *
FROM fVendas

-- A partir daqui, passei a utilizar a notação 'f%' para tabela fato, 'd%' para dimensão, 'dd%' para dimensão da dimensão e assim por diante

-- Além disso, passei a eliminar linhas nas tabelas dimensões que não apareciam na tabela fato, fiz isto através de subqueries

-- Eliminemos a redundancia de dTerritory
SELECT DISTINCT TerritoryID
FROM fVendas
ORDER BY TerritoryID
-- Varia de 1 a 10, então não preciso modificar a dTerritory

-- dTerritory
SELECT TerritoryID, CountryRegionCode, [Group]
FROM sales.SalesTerritory

-- Eliminemos a redundancia de dShipMethod
SELECT DISTINCT ShipMethodID
FROM fVendas
ORDER BY ShipMethodID
-- Somente 1 e 5

-- dShipMethod
SELECT ShipMethodID, Name
FROM Purchasing.ShipMethod
WHERE ShipMethodID IN (1,5)

-- Eliminemos a redundancia de dCustomer
SELECT DISTINCT CustomerID
FROM fVendas
ORDER BY CustomerID
-- Tem o mesmo número de linhas da tabela customer então não precisamos tratar

-- dCustomer
SELECT CustomerID, PersonID, StoreID
FROM sales.Customer

-- Eliminando redundancia de personperson
SELECT DISTINCT PersonID
FROM sales.Customer
WHERE PersonID IS NOT NULL
ORDER BY PersonID
-- Será necessário filtrar, vamos fazer uma subquery

-- ddPerson
SELECT BusinessEntityID AS PersonID, PersonType, (FirstName + ' ' + LastName) AS NomeCompleto, EmailPromotion
FROM person.Person
WHERE BusinessEntityID IN (SELECT DISTINCT PersonID
FROM sales.Customer
WHERE PersonID IS NOT NULL)

-- Eliminando redundancia de dStore
SELECT DISTINCT SalesPersonID
FROM fVendas
WHERE SalesPersonID IS NOT NULL
ORDER BY SalesPersonID
-- Será necessário filtrar, vamos fazer uma subquery

-- dStore
-- Criando uma View para auxiliar
CREATE VIEW StoreFiltrada AS
SELECT *
FROM sales.Store
WHERE SalesPersonID IN (SELECT DISTINCT SalesPersonID
FROM fVendas
WHERE SalesPersonID IS NOT NULL)

-- Aglutinando o nome dos vendedores e renomeando as colunas
-- dStore
SELECT SF.BusinessEntityID AS StoreID,Name AS StoreName, SalesPersonID
FROM StoreFiltrada SF
JOIN person.person PP
ON SF.SalesPersonID = PP.BusinessEntityID

-- dVendedor
SELECT DISTINCT SalesPersonID, (FirstName + ' ' + LastName) AS Vendedor
FROM StoreFiltrada SF
JOIN person.person PP
ON SF.SalesPersonID = PP.BusinessEntityID

-- dProduct
-- Demos um Join para simplificar (como são poucas linhas não vale a pena criar um novo ramo, apenas deixaria o modelo mais complicado)
SELECT ProductSubcategoryID, pps.Name AS ProductSubcategory, ppc.Name AS ProductCategory
FROM Production.ProductSubcategory as pps
JOIN
Production.ProductCategory as ppc
ON pps.ProductCategoryID = ppc.ProductCategoryID

-- dSpecialOffer
SELECT SpecialOfferID, DiscountPct, Type
FROM sales.SpecialOffer

-- Após isto, foram salvas todas estas consultas como arquivos CSV, juntamos em um só arquivo excel, na qual cada sheet (planilha) fora inserido um arquivo CSV
-- Todos os CSV extraídos do banco de dados estão zipados no arquivo 'sales_csvs_v2.rar' e a planilha foi salva como 'fVendas.xlsx'
-- Os demais tratamentos podem ser observados no editor Power Query no arquivo 'SalesV2.pbix'

-- Essa segunda versão apenas serviu como ponte para a terceira versão, já sendo capaz de gerar o relatório desejado, mas tendo problemas de escalabilidade devido 
-- às múltiplas dimensões que poderiam ser anexadas umas às outras 
