/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
-- ---------------------------------------------------------------------------

USE WideWorldImporters

    /*
    1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года
    (в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
    Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

    Пример:
    -------------+----------------------------
    Дата продажи | Нарастающий итог по месяцу
    -------------+----------------------------
     2015-01-29   | 4801725.31
     2015-01-30	 | 4801725.31
     2015-01-31	 | 4801725.31
     2015-02-01	 | 9626342.98
     2015-02-02	 | 9626342.98
     2015-02-03	 | 9626342.98
    Продажи можно взять из таблицы Invoices.
    Нарастающий итог должен быть без оконной функции.
    */

    напишите здесь свое решение

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

SELECT i.OrderID
     , c.CustomerName
     , o.OrderDate
     , ol.UnitPrice * ol.Quantity                                              AS SalesTotal
     , SUM(ol.UnitPrice * ol.Quantity) OVER (ORDER BY o.OrderID, c.CustomerID) AS CumSumMonth
  FROM Sales.Invoices i
       JOIN Sales.Orders o ON i.OrderID = o.OrderID
       JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
       JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
 WHERE o.OrderDate >= '20150101'
 ORDER BY o.OrderDate, o.OrderID, c.CustomerID;

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

SELECT t.YearOrderDate
     , t.MonthOrderDate
     , t.StockItemName
     , t.CntStockItems
  FROM (SELECT YEAR(o.OrderDate)                                                                       AS YearOrderDate
             , MONTH(o.OrderDate)                                                                      AS MonthOrderDate
             , si.StockItemName                                                                        AS StockItemName
             , COUNT(ol.StockItemID)                                                                   AS CntStockItems
             , ROW_NUMBER() OVER (PARTITION BY MONTH(o.OrderDate) ORDER BY COUNT(ol.StockItemID) DESC) AS Rang
          FROM Sales.Invoices i
               JOIN Sales.Orders o ON i.OrderID = o.OrderID
               JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
               JOIN Warehouse.StockItems si ON ol.StockItemID = si.StockItemID
         WHERE o.OrderDate BETWEEN '20160101' AND '20161231'
         GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate), si.StockItemName) t
 WHERE t.Rang BETWEEN 1 AND 2;

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

напишите здесь свое решение

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

SELECT TOP (1) WITH TIES
    o.SalespersonPersonID
     , p.FullName
     , c.CustomerID
     , c.CustomerName
     , o.OrderDate
     , ol.UnitPrice * ol.Quantity AS TransactionAmount
  FROM Application.People p
       JOIN Sales.Orders o ON o.SalespersonPersonID = p.PersonID AND p.IsSalesperson = 1
       JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
       JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
 ORDER BY ROW_NUMBER() OVER (PARTITION BY o.SalespersonPersonID ORDER BY o.OrderDate DESC);

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиента, его название, ид товара, цена, дата покупки.
*/

SELECT TOP (2) WITH TIES
    c.CustomerID
     , c.CustomerName
     , ol.StockItemID
     , ol.UnitPrice
     , o.OrderDate
  FROM Sales.Customers c
       JOIN Sales.Orders o ON o.CustomerID = c.CustomerID
       JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
 ORDER BY ROW_NUMBER() OVER (PARTITION BY o.CustomerID ORDER BY ol.UnitPrice DESC);