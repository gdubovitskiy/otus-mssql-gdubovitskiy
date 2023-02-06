/*
Напишите выборки для того, чтобы получить:
    1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
    2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
    3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ либо количеством единиц (Quantity) товара более 20 штуки присутствующей датой комплектации всего заказа (PickingCompletedWhen).
    4. Заказы поставщикам (Purchasing.Suppliers), которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName) и которые исполнены (IsOrderFinalized).
    5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника, который оформил заказ (SalespersonPerson). Сделать без подзапросов.
    6. Все ид и имена клиентов и их контактные телефоны, которые покупали товар "Chocolate frogs 250g".
 */

SELECT *
FROM Warehouse.StockItems i
WHERE i.StockItemName LIKE '%urgent%' OR i.StockItemName LIKE 'Animal%';

SELECT *
FROM Purchasing.Suppliers s
WHERE NOT EXISTS(SELECT 1 FROM Purchasing.PurchaseOrders po WHERE po.SupplierID = s.SupplierID);

SELECT *
FROM Sales.OrderLines
WHERE (UnitPrice > 100 OR Quantity > 20) AND PickingCompletedWhen IS NOT NULL;