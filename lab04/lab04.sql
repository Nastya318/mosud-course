--   сценарий                  минимальный маршрут соединения, акцент
--6	Повторные покупатели	customers по customer_unique_id → orders; сравнить первую и последнюю покупку.

-- 1. Построить основной запрос варианта минимум из трёх таблиц.
-- Основной запрос: сколько заказов и на какую сумму сделал каждый покупатель
SELECT
    c.customer_unique_id,        --уникальный ID человека
    COUNT(DISTINCT o.order_id) AS orders_cnt,--число заказов (DISTINCT — чтобы не размножить)
    SUM(oi.price)              AS total_sum  --сумма всех позиций
FROM olist.customers c
JOIN olist.orders      o  ON o.customer_id = c.customer_id   -- 1 заказ => 1 customer (N:1)
JOIN olist.order_items oi ON oi.order_id   = o.order_id  -- 1 заказ => N позиций (1:N)
GROUP BY c.customer_unique_id
HAVING COUNT(DISTINCT o.order_id) > 1   --оставляем только повторных
ORDER BY orders_cnt DESC
LIMIT 30;

--3. Добавить один LEFT JOIN так, чтобы в результате сохранялись объекты без связанных строк.
-- LEFT JOIN: даже если у покупателя нет отзыва, он останется в выборке
SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id)              AS orders_cnt,
    COUNT(DISTINCT r.review_id)             AS reviews_cnt,   --0, если отзывов нет
    ROUND(AVG(r.review_score)::numeric, 2)  AS avg_score
FROM olist.customers c
JOIN olist.orders       o  ON o.customer_id = c.customer_id
LEFT JOIN olist.order_reviews r ON r.order_id = o.order_id         --
GROUP BY c.customer_unique_id
HAVING COUNT(DISTINCT o.order_id) > 1
ORDER BY orders_cnt desc
LIMIT 20;

--4. Построить антисоединение: найти объекты, для которых связанной строки нет.

-- Антисоединение через LEFT JOIN + IS NULL
SELECT c.customer_unique_id, c.customer_id
FROM olist.customers c
LEFT JOIN olist.orders        o ON o.customer_id = c.customer_id
LEFT JOIN olist.order_reviews r ON r.order_id    = o.order_id
WHERE r.review_id IS NULL   --отзыва нет
LIMIT 20;

--5. Намеренно создать ошибочный JOIN, приводящий к размножению строк; показать, по какой причине изменилась сумма или count.
--Соединяем order_items и order_payments напрямую по order_id.
--Если в заказе 3 позиции и 2 оплаты — получим 3*2 = 6 строк вместо 3 или 2. Суммы завысятся.

-- заказы, у которых больше 1 позиции
SELECT
    oi.order_id,
    COUNT(*)        AS items_cnt, --сколько позиций в заказе
    SUM(oi.price)   AS sum_items   --корректная сумма
FROM olist.order_items oi
GROUP BY oi.order_id
HAVING COUNT(*) > 1   --оставляем только "многопозиционные"
ORDER BY items_cnt DESC
LIMIT 40;

SELECT
    o.order_id,
    SUM(oi.price)         AS sum_items, -- будет завышено
    SUM(p.payment_value)  AS sum_payments -- будет завышено
FROM olist.orders o
JOIN olist.order_items    oi ON oi.order_id = o.order_id
JOIN olist.order_payments p  ON p.order_id  = o.order_id
WHERE o.order_id = 'e481f51cbdc54678b7cc49136f2d6af7'   -- любой заказ с несколькими позициями
GROUP BY o.order_id;

--как должно быть
-- правильный вариант: раздельно
SELECT oi.order_id, SUM(oi.price) AS sum_items
FROM olist.order_items oi
WHERE oi.order_id = 'e481f51cbdc54678b7cc49136f2d6af7'
GROUP BY oi.order_id;

SELECT p.order_id, SUM(p.payment_value) AS sum_payments
FROM olist.order_payments p
WHERE p.order_id = 'e481f51cbdc54678b7cc49136f2d6af7'
GROUP BY p.order_id;


--6. Исправить ошибку предварительной агрегацией или изменением условия соединения.
-- исправленный вариант: сначала агрегируем каждую таблицу до 1 строки на заказ
WITH items_agg AS (
    SELECT order_id, SUM(price) AS sum_items
    FROM olist.order_items
    GROUP BY order_id
),
payments_agg AS (
    SELECT order_id, SUM(payment_value) AS sum_payments
    FROM olist.order_payments
    GROUP BY order_id
)
SELECT
    o.order_id,
    i.sum_items,
    p.sum_payments
FROM olist.orders o
LEFT JOIN items_agg    i ON i.order_id = o.order_id
LEFT JOIN payments_agg p ON p.order_id = o.order_id
WHERE o.order_id = 'e481f51cbdc54678b7cc49136f2d6af7';

