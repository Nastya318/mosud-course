
-- Практическая работа № 6. Подзапросы и логика предикатов
-- Вариант 6. Задача: Заказы, сумма платежей которых превышает 
-- сумму (price + freight_value) по позициям.


-- 1. Решить задачу варианта с использованием хотя бы одного подзапроса.
-- Используем скалярный подзапрос для суммы платежей и коррелированный 
-- подзапрос для суммы позиций. Оба подзапроса ссылаются на внешний заказ.

SELECT 
    o.order_id,
    o.order_status
FROM olist.orders o
WHERE 
    --скалярный подзапрос: считаем общую сумму платежей по текущему заказу
    (SELECT COALESCE(SUM(p.payment_value), 0) 
     FROM olist.order_payments p 
     WHERE p.order_id = o.order_id) 
    > 
    --коррелированный подзапрос: считаем сумму (цена + доставка) по позициям заказа
    (SELECT COALESCE(SUM(oi.price + oi.freight_value), 0) 
     FROM olist.order_items oi 
     WHERE oi.order_id = o.order_id);


-- 2. В решении должен присутствовать один скалярный подзапрос и один EXISTS/NOT EXISTS либо коррелированный подзапрос.
SELECT 
    o.order_id,
    o.order_status,
    -- скалярный: возвращает ровно одно значение (сумму) для каждого order_id
    (SELECT SUM(p.payment_value) 
     FROM olist.order_payments p 
     WHERE p.order_id = o.order_id) AS total_payments
FROM olist.orders o
WHERE 
    -- коррелированный с EXISTS
    EXISTS (
        SELECT 1 
        FROM olist.order_items oi 
        WHERE oi.order_id = o.order_id
    )
    -- cравниваем скалярный подзапрос с суммой товаров 
    AND (SELECT SUM(p.payment_value) FROM olist.order_payments p WHERE p.order_id = o.order_id) > 
        (SELECT SUM(oi.price + oi.freight_value) FROM olist.order_items oi WHERE oi.order_id = o.order_id);
--Запрос перебирает каждый заказ. 
--Сначала он проверяет через EXISTS, есть ли в этом заказе товары (отсеивает пустые заказы). 
--Затем он вычисляет сумму всех платежей по заказу (скалярный подзапрос) и сравнивает её 
--с суммой цен и доставки всех товаров. Если платежи превышают стоимость товаров, 
--заказ выводится в результат.

-- 3. Создать альтернативный вариант через JOIN или CTE с предварительной агрегацией.

WITH payment_totals AS (
    -- cчитаем сумму платежей по каждому заказу
    SELECT order_id, SUM(payment_value) AS total_payments
    FROM olist.order_payments
    GROUP BY order_id
),
item_totals AS (
    -- считаем сумму товаров и доставки по каждому заказу
    SELECT order_id, SUM(price + freight_value) AS total_items_cost
    FROM olist.order_items
    GROUP BY order_id
)
SELECT 
    o.order_id,
    o.order_status
FROM olist.orders o
JOIN payment_totals pt ON o.order_id = pt.order_id
JOIN item_totals it ON o.order_id = it.order_id
WHERE pt.total_payments > it.total_items_cost;

--Запрос создает две временные таблицы (CTE), где агрегирует суммы платежей и стоимость товаров для каждого заказа. 
--Затем он соединяет их с таблицей orders и выводит только те заказы, где сумма оплаты превышает стоимость товаров.


--4. Сравнить результаты оператором EXCEPT в обе стороны.

--Здесь мы берем наш первый вариант (с подзапросами) и второй вариант (с CTE) и проверяем, что они выдают абсолютно одинаковые списки заказов.
WITH query1 AS (
    SELECT o.order_id
    FROM olist.orders o
    WHERE EXISTS (SELECT 1 FROM olist.order_items oi WHERE oi.order_id = o.order_id)
      AND (SELECT SUM(p.payment_value) FROM olist.order_payments p WHERE p.order_id = o.order_id) > 
          (SELECT SUM(oi.price + oi.freight_value) FROM olist.order_items oi WHERE oi.order_id = o.order_id)
),
-- Второй вариант (через CTE и JOIN)
query2 AS (
    SELECT o.order_id
    FROM olist.orders o
    JOIN (SELECT order_id, SUM(payment_value) AS total_payments FROM olist.order_payments GROUP BY order_id) pt ON o.order_id = pt.order_id
    JOIN (SELECT order_id, SUM(price + freight_value) AS total_items_cost FROM olist.order_items GROUP BY order_id) it ON o.order_id = it.order_id
    WHERE pt.total_payments > it.total_items_cost
)
-- Сравниваем в обе стороны
SELECT order_id FROM query1
EXCEPT
SELECT order_id FROM query2

UNION ALL

SELECT order_id FROM query2
EXCEPT
SELECT order_id FROM query1;
--Запрос формирует два одинаковых по смыслу списка order_id разными способами и через EXCEPT (вычитание множеств) в обе стороны 
--(сверху вниз и снизу вверх) проверяет, есть ли между ними различия. 
--Если результатом выполнения будет пустая таблица (0 строк), значит, оба метода дали идентичный результат.

--5. Для подходящей части задачи показать пример ANY или ALL. Если он не нужен в финальном решении, оформить отдельный демонстрационный запрос.
--Поскольку в финальном решении операторы ANY или ALL не нужны (мы сравниваем две конкретные суммы), оформим отдельный демонстрационный запрос.
-- Например, найдем заказы, где сумма оплаты превышает вообще все цены товаров внутри этого же заказа (используем ALL).

SELECT 
    o.order_id,
    (SELECT SUM(payment_value) FROM olist.order_payments p WHERE p.order_id = o.order_id) AS total_paid
FROM olist.orders o
WHERE o.order_id IN (
    SELECT order_id FROM olist.order_payments
)
AND (SELECT SUM(payment_value) FROM olist.order_payments p WHERE p.order_id = o.order_id) > ALL (
    --сравниваем общую сумму платежа с ценой каждого!! товара в заказе
    SELECT oi.price 
    FROM olist.order_items oi 
    WHERE oi.order_id = o.order_id
);
--Запрос находит заказы, в которых общая сумма всех платежей строго больше, 
--чем цена любого (то есть самого дорогого) отдельного товара в этом заказе. 
-- Оператор ALL требует, чтобы условие > выполнялось для каждого значения из возвращаемого списка цен.