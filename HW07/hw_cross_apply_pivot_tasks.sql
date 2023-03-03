/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "07 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

-- промежуточные запросы для удобства проверки ------------>
-- SELECT SUBSTRING(c.CustomerName, 16, (LEN(c.CustomerName) - 16)) AS ClienName, c.CustomerID
--   FROM Sales.Customers c
--  WHERE c.CustomerID BETWEEN 2 AND 6
--  ORDER BY CustomerID;
--
-- SELECT CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, i.InvoiceDate), 0) AS DATE) AS InvoiceMonth
--      , t.ClienName
--      , Trans.TransactionAmount                                            AS Amount
--   FROM Sales.Invoices i
--        JOIN Sales.CustomerTransactions AS Trans ON I.InvoiceId = Trans.InvoiceID
--        JOIN (SELECT SUBSTRING(c.CustomerName, 16, (LEN(c.CustomerName) - 16)) AS ClienName, c.CustomerID FROM Sales.Customers c WHERE c.CustomerID BETWEEN 2 AND 6) t ON t.CustomerID = i.CustomerID
------------- <--------------- конец промежуточных подсчетов

SELECT InvoiceMonth
     , [Sylvanite, MT]
     , [Peeples Valley, AZ]
     , [Medicine Lodge, KS]
     , [Gasport, NY]
     , [Jessie, ND]
  FROM (
          SELECT
            Dates.InvoiceMonth AS InvoiceMonth
             , t.ClienName
             , i.InvoiceID
          FROM Sales.Invoices i
               JOIN Sales.Customers c ON c.CustomerID = i.CustomerID
               CROSS APPLY (SELECT InvoiceMonth = FORMAT(DATEADD(MM, DATEDIFF(MM, 0, I.InvoiceDate), 0), 'dd.MM.yyyy')) Dates
               CROSS APPLY (SELECT SUBSTRING(c.CustomerName, 16, (LEN(c.CustomerName) - 16)) AS ClienName, c.CustomerID FROM Sales.Customers c WHERE c.CustomerID BETWEEN 2 AND 6) t
        ) AS s
PIVOT (
      COUNT(s.InvoiceID)
      FOR s.ClienName IN ([Sylvanite, MT], [Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Jessie, ND])
) AS pvt
ORDER BY CAST(pvt.InvoiceMonth AS DATE);

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

SELECT CustomerName, AddressLine
  FROM (SELECT c.CustomerName, c.DeliveryAddressLine1, c.DeliveryAddressLine2, c.PostalAddressLine1, c.PostalAddressLine2
          FROM Sales.Customers c
         WHERE c.CustomerName LIKE 'Tailspin Toys%') AS S UNPIVOT (AddressLine FOR AddressLineList IN (DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2)) AS U;

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

SELECT CountryID
     , CountryName
     , Code
  FROM (SELECT c.CountryID, c.CountryName, CAST(c.IsoAlpha3Code AS NVARCHAR) AS IsoAlpha3Code, CAST(c.IsoNumericCode AS NVARCHAR) AS IsoNumericCode
          FROM Application.Countries c) AS S UNPIVOT (Code FOR CodeType IN (IsoAlpha3Code, IsoNumericCode)) AS U;

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT DISTINCT t.*
  FROM Sales.Invoices i
       CROSS APPLY (SELECT TOP 2
      c.CustomerID
                         , c.CustomerName
                         , ol.StockItemID
                         , ol.UnitPrice
                         , o.OrderDate
                      FROM Sales.Customers c
                           JOIN Sales.Orders o ON o.CustomerID = c.CustomerID
                           JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
                     WHERE i.CustomerID = c.CustomerID
                     ORDER BY ol.UnitPrice DESC) t;
