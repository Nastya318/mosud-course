
-- 1.  Построить запрос A и запрос B. Для каждого определить count(*) и count(DISTINCT product_id).

-- Множество A: уникальные product_id товаров, купленных клиентами из штата ES (только доставленные заказы)
SELECT DISTINCT oi.product_id
FROM olist.order_items oi
JOIN olist.orders o ON oi.order_id = o.order_id
JOIN olist.customers c ON o.customer_id = c.customer_id
WHERE c.customer_state = 'ES' 
  AND o.order_status = 'delivered';

-- Мощность множества A (количество уникальных товаров)
SELECT count(DISTINCT oi.product_id) AS count_A
FROM olist.order_items oi
JOIN olist.orders o ON oi.order_id = o.order_id
JOIN olist.customers c ON o.customer_id = c.customer_id
WHERE c.customer_state = 'ES' 
  AND o.order_status = 'delivered';

-- Множество B: уникальные product_id товаров, купленных клиентами из штата RJ (только доставленные заказы)
SELECT DISTINCT oi.product_id
FROM olist.order_items oi
JOIN olist.orders o ON oi.order_id = o.order_id
JOIN olist.customers c ON o.customer_id = c.customer_id
WHERE c.customer_state = 'RJ' 
  AND o.order_status = 'delivered';
--найшли все товары, которые покупали клиенты из штата ES в успешно доставленных заказах, и покажи каждый товар только один раз.

-- Мощность множества B
SELECT count(DISTINCT oi.product_id) AS count_B
FROM olist.order_items oi
JOIN olist.orders o ON oi.order_id = o.order_id
JOIN olist.customers c ON o.customer_id = c.customer_id
WHERE c.customer_state = 'RJ' 
  AND o.order_status = 'delivered';


-- 2. Получить A ∪ B с помощью UNION и UNION ALL. Объяснить разницу в количестве строк.
SELECT count(*) AS count_union
FROM (
SELECT DISTINCT oi.product_id
FROM olist.order_items oi
JOIN olist.orders o ON oi.order_id = o.order_id
JOIN olist.customers c ON o.customer_id = c.customer_id
WHERE c.customer_state = 'ES' AND o.order_status = 'delivered'

UNION

SELECT DISTINCT oi.product_id
FROM olist.order_items oi
JOIN olist.orders o ON oi.order_id = o.order_id
JOIN olist.customers c ON o.customer_id = c.customer_id
WHERE c.customer_state = 'RJ' AND o.order_status = 'delivered'
) t;

-- UNION ALL
-- Если товар покупали и в ES, и в RJ, он встретится дважды
SELECT count(*) AS count_union
FROM (
SELECT DISTINCT oi.product_id
FROM olist.order_items oi
JOIN olist.orders o ON oi.order_id = o.order_id
JOIN olist.customers c ON o.customer_id = c.customer_id
WHERE c.customer_state = 'ES' AND o.order_status = 'delivered'

UNION ALL

SELECT DISTINCT oi.product_id
FROM olist.order_items oi
JOIN olist.orders o ON oi.order_id = o.order_id
JOIN olist.customers c ON o.customer_id = c.customer_id
WHERE c.customer_state = 'RJ' AND o.order_status = 'delivered'
) t;

-- 3. Получить A ∩ B с помощью INTERSECT.

SELECT count(*) AS count_union
FROM (
SELECT DISTINCT oi.product_id
FROM olist.order_items oi
JOIN olist.orders o ON oi.order_id = o.order_id
JOIN olist.customers c ON o.customer_id = c.customer_id
WHERE c.customer_state = 'ES' AND o.order_status = 'delivered'

INTERSECT

SELECT DISTINCT oi.product_id
FROM olist.order_items oi
JOIN olist.orders o ON oi.order_id = o.order_id
JOIN olist.customers c ON o.customer_id = c.customer_id
WHERE c.customer_state = 'RJ' AND o.order_status = 'delivered'
) t;


-- 4. Получить A − B и B − A с помощью EXCEPT.

-- Товары, которые покупали в ES, но НЕ покупали в RJ
SELECT count(*) AS count_union
FROM (
SELECT DISTINCT oi.product_id
FROM olist.order_items oi
JOIN olist.orders o ON oi.order_id = o.order_id
JOIN olist.customers c ON o.customer_id = c.customer_id
WHERE c.customer_state = 'ES' AND o.order_status = 'delivered'

EXCEPT

SELECT DISTINCT oi.product_id
FROM olist.order_items oi
JOIN olist.orders o ON oi.order_id = o.order_id
JOIN olist.customers c ON o.customer_id = c.customer_id
WHERE c.customer_state = 'RJ' AND o.order_status = 'delivered'
) t;

-- Товары, которые покупали в RJ, но НЕ покупали в ES
SELECT count(*) AS count_except
FROM (
SELECT DISTINCT oi.product_id
FROM olist.order_items oi
JOIN olist.orders o ON oi.order_id = o.order_id
JOIN olist.customers c ON o.customer_id = c.customer_id
WHERE c.customer_state = 'RJ' AND o.order_status = 'delivered'

EXCEPT

SELECT DISTINCT oi.product_id
FROM olist.order_items oi
JOIN olist.orders o ON oi.order_id = o.order_id
JOIN olist.customers c ON o.customer_id = c.customer_id
WHERE c.customer_state = 'ES' AND o.order_status = 'delivered'
) t;


-- 5. Проверить коммутативность объединения и пересечения.

-- A ∪ B должно быть равно B ∪ A
SELECT 'A UNION B' AS операция, count(*) AS строк FROM (
    SELECT DISTINCT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON oi.order_id = o.order_id
    JOIN olist.customers c ON o.customer_id = c.customer_id
    WHERE c.customer_state = 'ES' AND o.order_status = 'delivered'
    UNION
    SELECT DISTINCT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON oi.order_id = o.order_id
    JOIN olist.customers c ON o.customer_id = c.customer_id
    WHERE c.customer_state = 'RJ' AND o.order_status = 'delivered'
) t

UNION ALL

SELECT 'B UNION A', count(*) FROM (
    SELECT DISTINCT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON oi.order_id = o.order_id
    JOIN olist.customers c ON o.customer_id = c.customer_id
    WHERE c.customer_state = 'RJ' AND o.order_status = 'delivered'
    UNION
    SELECT DISTINCT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON oi.order_id = o.order_id
    JOIN olist.customers c ON o.customer_id = c.customer_id
    WHERE c.customer_state = 'ES' AND o.order_status = 'delivered'
) t;

-- Коммутативность пересечения
SELECT 'A INTERSECT B' AS операция, count(*) AS строк FROM (
    SELECT DISTINCT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON oi.order_id = o.order_id
    JOIN olist.customers c ON o.customer_id = c.customer_id
    WHERE c.customer_state = 'ES' AND o.order_status = 'delivered'
    INTERSECT
    SELECT DISTINCT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON oi.order_id = o.order_id
    JOIN olist.customers c ON o.customer_id = c.customer_id
    WHERE c.customer_state = 'RJ' AND o.order_status = 'delivered'
) t

UNION ALL

SELECT 'B INTERSECT A', count(*) FROM (
    SELECT DISTINCT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON oi.order_id = o.order_id
    JOIN olist.customers c ON o.customer_id = c.customer_id
    WHERE c.customer_state = 'RJ' AND o.order_status = 'delivered'
    INTERSECT
    SELECT DISTINCT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON oi.order_id = o.order_id
    JOIN olist.customers c ON o.customer_id = c.customer_id
    WHERE c.customer_state = 'ES' AND o.order_status = 'delivered'
) t;


-- 6. Показать, что разность некоммутативна.

-- A − B НЕ равно B − A (количество строк будет разным)
SELECT 'A EXCEPT B' AS операция, count(*) AS строк FROM (
    SELECT DISTINCT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON oi.order_id = o.order_id
    JOIN olist.customers c ON o.customer_id = c.customer_id
    WHERE c.customer_state = 'ES' AND o.order_status = 'delivered'
    EXCEPT
    SELECT DISTINCT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON oi.order_id = o.order_id
    JOIN olist.customers c ON o.customer_id = c.customer_id
    WHERE c.customer_state = 'RJ' AND o.order_status = 'delivered'
) t

UNION ALL

SELECT 'B EXCEPT A', count(*) FROM (
    SELECT DISTINCT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON oi.order_id = o.order_id
    JOIN olist.customers c ON o.customer_id = c.customer_id
    WHERE c.customer_state = 'RJ' AND o.order_status = 'delivered'
    EXCEPT
    SELECT DISTINCT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON oi.order_id = o.order_id
    JOIN olist.customers c ON o.customer_id = c.customer_id
    WHERE c.customer_state = 'ES' AND o.order_status = 'delivered'
) t;


-- 7. Переписать пересечение без INTERSECT, используя EXISTS.

-- Товары из ES, для которых существует такой же товар в RJ

select count( DISTINCT oi1.product_id) as count_exists
FROM olist.order_items oi1
JOIN olist.orders o1 ON oi1.order_id = o1.order_id
JOIN olist.customers c1 ON o1.customer_id = c1.customer_id
WHERE c1.customer_state = 'ES' 
  AND o1.order_status = 'delivered'
  AND EXISTS ( --фильтрация результатов
      SELECT 1
      FROM olist.order_items oi2
      JOIN olist.orders o2 ON oi2.order_id = o2.order_id
      JOIN olist.customers c2 ON o2.customer_id = c2.customer_id
      WHERE c2.customer_state = 'RJ' 
        AND o2.order_status = 'delivered'
        AND oi2.product_id = oi1.product_id
  );
 


-- 8. Продемонстрировать появление дубликатов (мультимножество).

-- Убираем DISTINCT. Один и тот же product_id встретится много раз,
-- так как один товар мог быть куплен разными клиентами из ES много раз.
SELECT count(oi.product_id) as count
FROM olist.order_items oi
JOIN olist.orders o ON oi.order_id = o.order_id
JOIN olist.customers c ON o.customer_id = c.customer_id
WHERE c.customer_state = 'ES' 
  AND o.order_status = 'delivered';
 --  было 1648 


