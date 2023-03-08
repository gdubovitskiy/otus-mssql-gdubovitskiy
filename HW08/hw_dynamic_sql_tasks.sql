/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Динамический SQL".

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

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/

DECLARE @SQLRequest AS NVARCHAR(MAX)
DECLARE @ColumnName AS NVARCHAR(MAX)

SELECT @ColumnName = ISNULL(@ColumnName + ',', '') + QUOTENAME(CustomerName)
FROM (SELECT c.CustomerName
FROM Sales.Customers c
-- WHERE c.CustomerID BETWEEN 2 AND 6
) AS CustomerNameList

SET @SQLRequest =
N'SELECT InvoiceMonth, ' + @ColumnName + '
  FROM (
          SELECT
            Dates.InvoiceMonth AS InvoiceMonth
             , c.CustomerName
             , i.InvoiceID
          FROM Sales.Invoices i
               JOIN Sales.Customers c ON c.CustomerID = i.CustomerID
               CROSS APPLY (SELECT InvoiceMonth = FORMAT(DATEADD(MM, DATEDIFF(MM, 0, I.InvoiceDate), 0), ''dd.MM.yyyy'')) Dates
        ) AS s
PIVOT (
      COUNT(s.InvoiceID)
      FOR s.CustomerName IN (' + @ColumnName + ')
) AS pvt
ORDER BY CAST(pvt.InvoiceMonth AS DATE);'

EXEC sp_executesql @SQLRequest