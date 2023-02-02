/*
 Напишите выборки для того, чтобы получить:
 Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
 */


SELECT *
FROM Purchasing.Suppliers s
WHERE NOT EXISTS(SELECT 1 FROM Purchasing.PurchaseOrders po WHERE po.SupplierID = s.SupplierID);