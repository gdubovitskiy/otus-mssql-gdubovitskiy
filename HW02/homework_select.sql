/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT i.StockItemID, i.StockItemName
  FROM Warehouse.StockItems i
 WHERE i.StockItemName LIKE '%urgent%'
    OR i.StockItemName LIKE 'Animal%';

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT s.SupplierID, s.SupplierName
  FROM Purchasing.Suppliers s
       LEFT JOIN Purchasing.PurchaseOrders po ON po.SupplierID = s.SupplierID
 WHERE po.SupplierID IS NULL

-- 2 более быстрый вариант решения этой задачи при помощи NOT EXISTS
SELECT s.SupplierID, s.SupplierName
  FROM Purchasing.Suppliers s
 WHERE NOT EXISTS(SELECT 1 FROM Purchasing.PurchaseOrders po WHERE po.SupplierID = s.SupplierID);

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT o.OrderID
     , FORMAT(o.OrderDate, 'dd.MM.yyyy', 'en-US')  AS OrderDate
     , FORMAT(o.OrderDate, 'MMMM', 'en-US')        AS MonthNameOfOrderDate
     , DATEPART(QUARTER, o.OrderDate)              AS QuarterOfOrderDate
     , CEILING(DATEPART(MONTH, o.OrderDate) / 4.0) AS TrioOfOrderDate
     , c.CustomerName
  FROM Sales.Orders o
       LEFT JOIN Sales.OrderLines ol ON ol.OrderID = o.OrderID
       LEFT JOIN Sales.Customers c ON c.CustomerID = o.CustomerID
 WHERE 1 = 1
   AND ((ol.UnitPrice > 100) OR (ol.Quantity > 20 AND ol.PickingCompletedWhen IS NOT NULL))
 ORDER BY QuarterOfOrderDate, TrioOfOrderDate, OrderDate;

-- Вариант этого запроса с постраничной выборкой
SELECT o.OrderID
     , FORMAT(o.OrderDate, 'dd.MM.yyyy', 'en-US')  AS OrderDate
     , FORMAT(o.OrderDate, 'MMMM', 'en-US')        AS MonthNameOfOrderDate
     , DATEPART(QUARTER, o.OrderDate)              AS QuarterOfOrderDate
     , CEILING(DATEPART(MONTH, o.OrderDate) / 4.0) AS TrioOfOrderDate
     , c.CustomerName
  FROM Sales.Orders o
       LEFT JOIN Sales.OrderLines ol ON ol.OrderID = o.OrderID
       LEFT JOIN Sales.Customers c ON c.CustomerID = o.CustomerID
 WHERE 1 = 1
   AND ((ol.UnitPrice > 100) OR (ol.Quantity > 20 AND ol.PickingCompletedWhen IS NOT NULL))
 ORDER BY QuarterOfOrderDate, TrioOfOrderDate, OrderDate
OFFSET 1000 ROWS FETCH FIRST 100 ROWS ONLY;

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT dm.DeliveryMethodName
     , po.ExpectedDeliveryDate
     , s.SupplierName
     , p.FullName
  FROM Purchasing.Suppliers s
       LEFT JOIN Purchasing.PurchaseOrders po ON s.SupplierID = po.SupplierID
       INNER JOIN Application.DeliveryMethods dm ON po.DeliveryMethodID = dm.DeliveryMethodID
       INNER JOIN Application.People p ON po.ContactPersonID = p.PersonID
 WHERE 1 = 1
   AND (po.ExpectedDeliveryDate BETWEEN '20130101' AND EOMONTH('20130101'))
   AND (dm.DeliveryMethodName IN ('Air Freight', 'Refrigerated Air Freight'))
   AND IsOrderFinalized = 1;

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP 10
    o.OrderDate
     , c.CustomerName
     , p.FullName AS SalespersonPerson
  FROM Sales.Orders o
       INNER JOIN Sales.Customers c ON c.CustomerID = o.CustomerID
       INNER JOIN Application.People p ON p.PersonID = o.SalespersonPersonID AND p.IsSalesperson = 1
 ORDER BY OrderDate DESC;

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT c.CustomerID
     , si.StockItemID
     , c.CustomerName
     , c.PhoneNumber
  FROM Sales.Orders o
       INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
       INNER JOIN Warehouse.StockItems si ON si.StockItemID = ol.StockItemID
       INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
 WHERE si.StockItemName = 'Chocolate frogs 250g';