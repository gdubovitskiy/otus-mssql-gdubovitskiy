/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Подзапросы, CTE, временные таблицы".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

SELECT p.PersonID, p.FullName
  FROM Application.People p
 WHERE p.IsSalesperson = 1
   AND p.IsSalesperson NOT IN (SELECT DISTINCT i.SalespersonPersonID FROM Sales.Invoices i WHERE i.InvoiceDate = '20150704')
 ORDER BY p.PersonID;

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

SELECT StockItemID
     , StockItemName
     , UnitPrice
  FROM Warehouse.StockItems
 WHERE UnitPrice = (SELECT MIN(UnitPrice) FROM Warehouse.StockItems);

SELECT StockItemID
     , StockItemName
     , UnitPrice
  FROM Warehouse.StockItems
 WHERE UnitPrice = (SELECT TOP 1 StockItems.UnitPrice FROM Warehouse.StockItems ORDER BY StockItems.UnitPrice);

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

-- просто ТОП-5 (ниже версия для уникальных)
  WITH CTE_TOP5_MAX_PAYMENTS_CUSTOMER AS (SELECT TOP 5 ct.CustomerID, ct.TransactionAmount FROM Sales.CustomerTransactions ct ORDER BY ct.TransactionAmount DESC)

SELECT c.CustomerID
     , c.CustomerName
     , cte.TransactionAmount
  FROM Sales.Customers c
       INNER JOIN CTE_TOP5_MAX_PAYMENTS_CUSTOMER cte ON cte.CustomerID = c.CustomerID
 ORDER BY cte.TransactionAmount DESC;


SELECT c.CustomerID
     , c.CustomerName
     , t.TransactionAmount
  FROM Sales.Customers c
       INNER JOIN (SELECT TOP 5 ct.CustomerID, ct.TransactionAmount FROM Sales.CustomerTransactions ct ORDER BY ct.TransactionAmount DESC) t ON t.CustomerID = c.CustomerID
 ORDER BY t.TransactionAmount DESC;

-- ТОП-5 уникальных
SELECT c.CustomerID
     , c.CustomerName
     , t.MaxTransactionAmount
  FROM Sales.Customers c
       INNER JOIN (SELECT TOP 5 ct.CustomerID, MAX(ct.TransactionAmount) AS MaxTransactionAmount FROM Sales.CustomerTransactions ct GROUP BY ct.CustomerID ORDER BY MaxTransactionAmount DESC) t ON t.CustomerID = c.CustomerID
 ORDER BY t.MaxTransactionAmount DESC;


/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

SELECT DISTINCT
       cs.CityID
     , cs.CityName
  FROM Sales.Orders o
       JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
       JOIN Sales.Customers c ON c.CustomerID = o.CustomerID
       JOIN Application.People p ON p.PersonID = o.PickedByPersonID
       JOIN Application.Cities cs ON cs.CityID = c.DeliveryCityID
       JOIN (SELECT TOP 3 si.StockItemID, si.StockItemName, si.UnitPrice FROM Warehouse.StockItems si ORDER BY UnitPrice DESC) t ON t.StockItemID = ol.StockItemID
ORDER BY cs.CityID;