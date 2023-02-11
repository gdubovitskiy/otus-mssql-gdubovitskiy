/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "03 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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

USE WideWorldImporters;

/*
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT YEAR(o.OrderDate)               AS YearOrderDate
     , MONTH(o.OrderDate)              AS MonthOrderDate
     , AVG(ol.UnitPrice * ol.Quantity) AS AvgUnitPrice
     , SUM(ol.UnitPrice * ol.Quantity) AS SumUnitPrice
  FROM Sales.Invoices i
       JOIN Sales.Orders o ON i.OrderID = o.OrderID
       JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
 GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
 ORDER BY YearOrderDate, MonthOrderDate;

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
Сортировка по году и месяцу.

*/

SELECT YEAR(o.OrderDate)               AS YearOrderDate
     , MONTH(o.OrderDate)              AS MonthOrderDate
     , SUM(ol.UnitPrice * ol.Quantity) AS SumUnitPrice
  FROM Sales.Invoices i
       JOIN Sales.Orders o ON i.OrderID = o.OrderID
       JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
 GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
HAVING SUM(ol.UnitPrice * ol.Quantity) > 4600000
 ORDER BY YearOrderDate, MonthOrderDate;

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году, месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT YEAR(o.OrderDate)               AS YearOrderDate
     , MONTH(o.OrderDate)              AS MonthOrderDate
     , si.StockItemName                AS StockItemName
     , SUM(ol.UnitPrice * ol.Quantity) AS SumUnitPrice
     , MIN(o.OrderDate)                AS FirstOrderDate
     , SUM(ol.Quantity)                AS SumQuantity
  FROM Sales.Invoices i
       JOIN Sales.Orders o ON i.OrderID = o.OrderID
       JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
       JOIN Warehouse.StockItems si ON ol.StockItemID = si.StockItemID
 GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate), si.StockItemName
HAVING SUM(ol.Quantity) < 50
 ORDER BY YearOrderDate, MonthOrderDate;

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
4. Написать второй запрос ("Отобразить все месяцы, где общая сумма продаж превысила 4 600 000") 
за период 2015 год так, чтобы месяц, в котором сумма продаж была меньше указанной суммы также отображался в результатах,
но в качестве суммы продаж было бы '-'.
Сортировка по году и месяцу.

Пример результата:
-----+-------+------------
Year | Month | SalesTotal
-----+-------+------------
2015 | 1     | -
2015 | 2     | -
2015 | 3     | -
2015 | 4     | 5073264.75
2015 | 5     | -
2015 | 6     | -
2015 | 7     | 5155672.00
2015 | 8     | -
2015 | 9     | 4662600.00
2015 | 10    | -
2015 | 11    | -
2015 | 12    | -

*/


DROP TABLE IF EXISTS #result;
GO

DECLARE @date_start DATE = '20150101', @date_end DATE = '20151201';

  WITH cte_counter_list(Counter) AS (SELECT TOP (DATEDIFF(MONTH, @date_start, @date_end) + 1) -- 12 месяцев = TOP (12)
                                            ROW_NUMBER() OVER (ORDER BY [object_id])          -- обычный счетчик 1...N
                                       FROM sys.all_objects)

SELECT YEAR(DATEADD(MONTH, Counter - 1, @date_start)) AS Year, MONTH(DATEADD(MONTH, Counter - 1, @date_start)) AS Month
  INTO #result
  FROM cte_counter_list

SELECT res.Year
     , res.Month
     , IIF(t.SumUnitPrice IS NULL, '-', CONVERT(VARCHAR, t.SumUnitPrice))
  FROM #result res
       LEFT JOIN (SELECT YEAR(o.OrderDate)               AS YearOrderDate
                       , MONTH(o.OrderDate)              AS MonthOrderDate
                       , SUM(ol.UnitPrice * ol.Quantity) AS SumUnitPrice
                    FROM Sales.Invoices i
                         JOIN Sales.Orders o ON i.OrderID = o.OrderID
                         JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
                   GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
                  HAVING SUM(ol.UnitPrice * ol.Quantity) > 4600000) t ON res.Year = t.YearOrderDate AND res.Month = t.MonthOrderDate
 ORDER BY Year, Month