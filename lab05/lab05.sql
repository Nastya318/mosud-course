-- Практическая работа № 5. Кванторы, EXISTS и реляционное деление
-- Вариант 6. Множество штатов S: PA, AM, RO


-- 1. Создать CTE target_states из трёх значений своего варианта.
WITH target_states(state) AS (
    VALUES ('PA'), ('AM'), ('RO')
),
--Смысл этого шага в том, чтобы один раз зафиксировать множество штатов и дальше ссылаться на него по имени, не дублируя названия в каждом запросе.

-- 2. Реализовать условие «категория продавалась во всех штатах S» через двойной NOT EXISTS.
-- Логика: Найти категорию, для которой не существует штата из S, 
-- в котором ...не было бы... заказов с этой категорией.
res_not_exists AS (
    SELECT DISTINCT p.product_category_name
    FROM olist.products p
    WHERE p.product_category_name IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 
          FROM target_states ts
          WHERE NOT EXISTS (
              SELECT 1
              FROM olist.orders o
              JOIN olist.customers c ON o.customer_id = c.customer_id
              JOIN olist.order_items oi ON o.order_id = oi.order_id
              JOIN olist.products p2 ON oi.product_id = p2.product_id  -- джойним через products
              WHERE c.customer_state = ts.state
                AND p2.product_category_name = p.product_category_name  -- проверяем по категории, а не по product_id
                AND o.order_status = 'delivered'
          )
      )
)
SELECT * FROM res_not_exists ORDER BY 1;

--Во втором шаге реализуется классическое реляционное деление через двойной NOT EXISTS. 
--Мы берём таблицу products и перебираем все уникальные названия категорий, исключая NULL-значения.
--Для каждой категории запускается внешний NOT EXISTS, который проходит по таблице target_states, 
--то есть по нашим трём штатам. Внутри него находится ещё один, внутренний NOT EXISTS, 
--который через соединения таблиц orders, customers и order_items ищет факт того, что товар данной 
--категории был куплен жителем конкретного штата и заказ при этом имеет статус delivered. 
--Работает это по принципу двойного отрицания: если для категории находится хоть один штат, 
--в котором она не продавалась, внутренний запрос возвращает строку, NOT EXISTS становится ложью,
-- и категория отбрасывается. Если же категория присутствует во всех трёх штатах, внутренний запрос
-- всегда оказывается пустым, срабатывает двойное отрицание, 
--и категория попадает в итоговый результат.

-- 3. Реализовать то же через GROUP BY/HAVING COUNT (DISTINCT customer_state).
WITH target_states(state) AS (
    VALUES ('PA'), ('AM'), ('RO')
),
res_group_by AS (
    SELECT p.product_category_name
    FROM olist.products p
    JOIN olist.order_items oi ON p.product_id = oi.product_id
    JOIN olist.orders o ON oi.order_id = o.order_id
    JOIN olist.customers c ON o.customer_id = c.customer_id
    JOIN target_states ts ON c.customer_state = ts.state --соединяем только с нужными штатами
    WHERE p.product_category_name IS NOT NULL
      AND o.order_status = 'delivered'
    GROUP BY p.product_category_name
    HAVING COUNT(DISTINCT c.customer_state) = (SELECT COUNT(*) FROM target_states) --сравниваем с мощностью делителя
),
--Мы соединяем пять таблиц: products, order_items, orders, customers и наш CTE target_states, 
--чтобы сразу отсечь все штаты, не входящие в множество S. 
--Затем фильтруем только доставленные заказы и группируем всё по названию категории. 
--Внутри каждой группы считаем количество уникальных штатов, 
--в которых категория была продана, с помощью COUNT(DISTINCT c.customer_state). 
--В условии HAVING требуем, чтобы это число было строго равно количеству штатов в делителе, 
--то есть трём. Если категория продавалась только в двух штатах, счётчик будет равен двум, 
--и такое значение отсеется.

-- 4. Реализовать то же через EXCEPT и NOT EXISTS.
-- Логика: Из всех штатов вычитаем те, где категория продавалась. 
-- Если осталось пусто (NOT EXISTS), значит категория есть во всех штатах.
res_except AS (
    SELECT DISTINCT p.product_category_name
    FROM olist.products p
    WHERE p.product_category_name IS NOT NULL
      AND NOT EXISTS (
          (SELECT state FROM target_states)
          EXCEPT
          (SELECT DISTINCT c.customer_state
           FROM olist.customers c
           JOIN olist.orders o ON c.customer_id = o.customer_id
           JOIN olist.order_items oi ON o.order_id = oi.order_id
           WHERE oi.product_id = p.product_id
             AND o.order_status = 'delivered')
      )
)
--Четвёртый шаг использует оператор EXCEPT в сочетании с NOT EXISTS. 
--Мы снова перебираем категории из таблицы products и для каждой проверяем условие NOT EXISTS.
-- Внутри него берём все штаты из target_states и вычитаем из них те штаты, 
--где эта категория реально продавалась. Вычитание делается через EXCEPT, 
--а штаты находятся соединением таблиц customers, orders и order_items 
--с фильтрацией по product_id и статусу delivered. 
--Если категория продаётся во всех трёх штатах, после вычитания от нашего множества 
--не останется ни одного элемента, то есть получится пустое множество. 
--Оператор NOT EXISTS от пустого множества возвращает истину, и категория попадает в ответ.
-- 

--вывод результатов трех методов
WITH target_states(state) AS (
    VALUES ('PA'), ('AM'), ('RO')
),


--метод 1
SELECT * FROM res_not_exists ORDER BY 1;

--метод 2
--SELECT * FROM res_group_by ORDER BY 1;

--метод 3
--SELECT * FROM res_except ORDER BY 1;
SELECT 'Метод 1' AS метод, product_category_name FROM res_not_exists
UNION ALL
SELECT 'Метод 2', product_category_name FROM res_group_by
UNION ALL
SELECT 'Метод 3', product_category_name FROM res_except;
WITH target_states(state) AS (
    VALUES ('PA'), ('AM'), ('RO')
),
-- Сначала быстро находим кандидатов через GROUP BY
candidates AS (
    SELECT p.product_category_name
    FROM olist.products p
    JOIN olist.order_items oi ON p.product_id = oi.product_id
    JOIN olist.orders o ON oi.order_id = o.order_id
    JOIN olist.customers c ON o.customer_id = c.customer_id
    JOIN target_states ts ON c.customer_state = ts.state
    WHERE p.product_category_name IS NOT NULL
      AND o.order_status = 'delivered'
    GROUP BY p.product_category_name
    HAVING COUNT(DISTINCT c.customer_state) = 3
),
-- А потом проверяем их через EXCEPT (категорий теперь мало)
res_except AS (
    SELECT DISTINCT c.product_category_name
    FROM candidates c
    WHERE NOT EXISTS (
        (SELECT state FROM target_states)
        EXCEPT
        (SELECT DISTINCT cu.customer_state
         FROM olist.customers cu
         JOIN olist.orders o ON cu.customer_id = o.customer_id
         JOIN olist.order_items oi ON o.order_id = oi.order_id
         JOIN olist.products p ON oi.product_id = p.product_id
         WHERE p.product_category_name = c.product_category_name
           AND o.order_status = 'delivered')
    )
)
SELECT 'Метод 3 (оптимизированный)' AS метод, product_category_name 
FROM res_except
ORDER BY product_category_name;


-- 5. Сравнить множества результатов оператором EXCEPT в обе стороны и доказать их эквивалентность на данных.

-- Если запросы ниже возвращают 0 строк, множества полностью идентичны.


-- Разница между методом 1 и методом 2
SELECT 'Method 1 EXCEPT Method 2' AS check_type, product_category_name FROM res_not_exists 
EXCEPT 
SELECT 'Method 1 EXCEPT Method 2', product_category_name FROM res_group_by;

SELECT 'Method 2 EXCEPT Method 1' AS check_type, product_category_name FROM res_group_by 
EXCEPT 
SELECT 'Method 2 EXCEPT Method 1', product_category_name FROM res_not_exists;

-- Разница между методом 1 и методом 3
SELECT 'Method 1 EXCEPT Method 3' AS check_type, product_category_name FROM res_not_exists 
EXCEPT 
SELECT 'Method 1 EXCEPT Method 3', product_category_name FROM res_except;

SELECT 'Method 3 EXCEPT Method 1' AS check_type, product_category_name FROM res_except 
EXCEPT 
SELECT 'Method 3 EXCEPT Method 1', product_category_name FROM res_not_exists;


-- 5. Проверка эквивалентности
WITH target_states(state) AS (
    VALUES ('PA'), ('AM'), ('RO')
),
res_not_exists AS (
    SELECT DISTINCT p.product_category_name
    FROM olist.products p
    WHERE p.product_category_name IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 
          FROM target_states ts
          WHERE NOT EXISTS (
              SELECT 1
              FROM olist.orders o
              JOIN olist.customers c ON o.customer_id = c.customer_id
              JOIN olist.order_items oi ON o.order_id = oi.order_id
              JOIN olist.products p2 ON oi.product_id = p2.product_id  -- джойним через products
              WHERE c.customer_state = ts.state
                AND p2.product_category_name = p.product_category_name  -- проверяем по категории, а не по product_id
                AND o.order_status = 'delivered'
          )
      )
),
res_group_by AS (
    SELECT p.product_category_name
    FROM olist.products p
    JOIN olist.order_items oi ON p.product_id = oi.product_id
    JOIN olist.orders o ON oi.order_id = o.order_id
    JOIN olist.customers c ON o.customer_id = c.customer_id
    
    WHERE p.product_category_name IS NOT NULL
      AND o.order_status = 'delivered'
      AND c.customer_state IN ('PA', 'AM', 'RO')  -- вместо JOIN с target_states
    GROUP BY p.product_category_name
    HAVING COUNT(DISTINCT c.customer_state) = (SELECT COUNT(*) FROM target_states)
)

-- Разница между методом 1 и методом 2 (должно быть 0 строк)
SELECT 'Метод 1 минус Метод 2' AS проверка, product_category_name FROM res_not_exists
EXCEPT
SELECT 'Метод 1 минус Метод 2', product_category_name FROM res_group_by

UNION ALL

SELECT 'Метод 2 минус Метод 1', product_category_name FROM res_group_by
EXCEPT
SELECT 'Метод 2 минус Метод 1', product_category_name FROM res_not_exists;

-- Проверяем категорию 'bebes' вручную
SELECT 
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS order_count
FROM olist.products p
JOIN olist.order_items oi ON p.product_id = oi.product_id
JOIN olist.orders o ON oi.order_id = o.order_id
JOIN olist.customers c ON o.customer_id = c.customer_id
WHERE p.product_category_name = 'bebes'
  AND o.order_status = 'delivered'
  AND c.customer_state IN ('PA', 'AM', 'RO')
GROUP BY c.customer_state
ORDER BY c.customer_state;


-- Проверка эквивалентности Метода 1 (NOT EXISTS) и Метода 3 (EXCEPT)
-- Оба метода исправлены: сравнение идёт по product_category_name,
-- а не по product_id.


WITH target_states(state) AS (
    VALUES ('PA'), ('AM'), ('RO')
),

-- Метод 1: двойной NOT EXISTS (проверка по категории)
res_not_exists AS (
    SELECT DISTINCT p.product_category_name
    FROM olist.products p
    WHERE p.product_category_name IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 
          FROM target_states ts
          WHERE NOT EXISTS (
              SELECT 1
              FROM olist.orders o
              JOIN olist.customers c ON o.customer_id = c.customer_id
              JOIN olist.order_items oi ON o.order_id = oi.order_id
              JOIN olist.products p2 ON oi.product_id = p2.product_id
              WHERE c.customer_state = ts.state
                AND p2.product_category_name = p.product_category_name
                AND o.order_status = 'delivered'
          )
      )
),

-- Метод 3: EXCEPT + NOT EXISTS (проверка по категории)
candidates AS (
    SELECT p.product_category_name
    FROM olist.products p
    JOIN olist.order_items oi ON p.product_id = oi.product_id
    JOIN olist.orders o ON oi.order_id = o.order_id
    JOIN olist.customers c ON o.customer_id = c.customer_id
    JOIN target_states ts ON c.customer_state = ts.state
    WHERE p.product_category_name IS NOT NULL
      AND o.order_status = 'delivered'
    GROUP BY p.product_category_name
    HAVING COUNT(DISTINCT c.customer_state) = 3
),
-- А потом проверяем их через EXCEPT (категорий теперь мало)
res_except AS (
    SELECT DISTINCT c.product_category_name
    FROM candidates c
    WHERE NOT EXISTS (
        (SELECT state FROM target_states)
        EXCEPT
        (SELECT DISTINCT cu.customer_state
         FROM olist.customers cu
         JOIN olist.orders o ON cu.customer_id = o.customer_id
         JOIN olist.order_items oi ON o.order_id = oi.order_id
         JOIN olist.products p ON oi.product_id = p.product_id
         WHERE p.product_category_name = c.product_category_name
           AND o.order_status = 'delivered')
    )
)

-- Разница в обе стороны. Если оба запроса вернут 0 строк — методы эквивалентны.
SELECT 'Метод 1 минус Метод 3' AS проверка, product_category_name 
FROM res_not_exists
EXCEPT
SELECT 'Метод 1 минус Метод 3', product_category_name 
FROM res_except

UNION ALL

SELECT 'Метод 3 минус Метод 1', product_category_name 
FROM res_except
EXCEPT
SELECT 'Метод 3 минус Метод 1', product_category_name 
FROM res_not_exists;
-- 6. Для одной найденной категории вывести диагностическую таблицу: категория → штат → число заказов.


-- новый!! 
SELECT 
    p.product_category_name AS category,
    c.customer_state AS state,
    COUNT(DISTINCT o.order_id) AS order_count
FROM olist.products p
JOIN olist.order_items oi ON p.product_id = oi.product_id
JOIN olist.orders o ON oi.order_id = o.order_id
JOIN olist.customers c ON o.customer_id = c.customer_id
WHERE p.product_category_name = (
    --берем самую популярную категорию, которая есть во всех 3 штатах
    SELECT p2.product_category_name
    FROM olist.products p2
    JOIN olist.order_items oi2 ON p2.product_id = oi2.product_id
    JOIN olist.orders o2 ON oi2.order_id = o2.order_id
    JOIN olist.customers c2 ON o2.customer_id = c2.customer_id
    WHERE p2.product_category_name IS NOT NULL --Защита от NULL
      AND p2.product_category_name != ''  --Защита от пустых строк
      AND o2.order_status = 'delivered'
      AND c2.customer_state IN ('PA', 'AM', 'RO')
    GROUP BY p2.product_category_name
    HAVING COUNT(DISTINCT c2.customer_state) = 3
    ORDER BY COUNT(DISTINCT oi2.order_id) DESC --добавили сортировку (самая частая)
    LIMIT 1
)
AND p.product_category_name IS NOT NULL --исключаем NULL в основной выборке
AND p.product_category_name != ''   --исключаем пустые строки
AND c.customer_state IN ('PA', 'AM', 'RO')
AND o.order_status = 'delivered'
GROUP BY p.product_category_name, c.customer_state
ORDER BY c.customer_state;


-- 7. Проверка поведения при пустом target_states

-- Создаем пустой CTE для проверки
WITH target_states AS (
    SELECT state FROM (VALUES ('нет_такого_штата')) AS t(state) WHERE 1=0 
    --или SELECT NULL AS state WHERE 1=0
)
--Найти категории, для которых не существует такого штата из списка, где не было бы продаж этой категории
-- Вариант 1: Двойной NOT EXISTS (Логически верный)
, all_categories AS (
    SELECT DISTINCT product_category_name 
    FROM olist.products 
    WHERE product_category_name IS NOT NULL
)
, result_not_exists AS (
    SELECT ac.product_category_name
    FROM all_categories ac
    WHERE NOT EXISTS (
        SELECT 1 FROM target_states ts
        WHERE NOT EXISTS (
            SELECT 1 
            FROM olist.order_items oi
            JOIN olist.orders o ON oi.order_id = o.order_id
            JOIN olist.customers c ON o.customer_id = c.customer_id
            JOIN olist.products p ON oi.product_id = p.product_id
            WHERE p.product_category_name = ac.product_category_name
              AND c.customer_state = ts.state
              AND o.order_status = 'delivered'
        )
    )
)
--Данные просто отфильтровываются на этапе соединения. До блока GROUP BY не доходит ни одной строки, поэтому запрос возвращает 0.
-- Вариант 2: GROUP BY / HAVING (Логически ошибочный при пустом делителе)
, result_having AS (
    SELECT p.product_category_name
    FROM olist.products p
    JOIN olist.order_items oi ON p.product_id = oi.product_id
    JOIN olist.orders o ON oi.order_id = o.order_id
    JOIN olist.customers c ON o.customer_id = c.customer_id
    JOIN target_states ts ON c.customer_state = ts.state
    WHERE p.product_category_name IS NOT NULL
      AND o.order_status = 'delivered'
    GROUP BY p.product_category_name
    HAVING COUNT(DISTINCT c.customer_state) = (SELECT COUNT(*) FROM target_states)
)

-- Считаем количество строк в каждом варианте
SELECT 
    (SELECT COUNT(*) FROM result_not_exists) AS count_not_exists,
    (SELECT COUNT(*) FROM result_having) AS count_having;
--При пустом делителе двойной NOT EXISTS вывел 74, 
--так как по законам логики утверждение «для всех элементов пустого множества» всегда истинно,
--поэтому возвращаются абсолютно все существующие категории. 
--Метод HAVING вывел 0, потому что из-за отсутствия штатов при соединении таблиц 
--не находится ни одной продажи, база данных не может сгруппировать строки, 
--и условие COUNT(...) = 0 просто не с чем сравнивать.


-- 8. Дополнительно: найти продавцов, которые продавали товары покупателям каждого из трёх штатов.
WITH target_states(state) AS (
    VALUES ('PA'), ('AM'), ('RO')
)
SELECT DISTINCT s.seller_id
FROM olist.sellers s
WHERE NOT EXISTS (
    SELECT 1 
    FROM target_states ts
    WHERE NOT EXISTS (
        SELECT 1
        FROM olist.order_items oi
        JOIN olist.orders o ON oi.order_id = o.order_id
        JOIN olist.customers c ON o.customer_id = c.customer_id
        WHERE oi.seller_id = s.seller_id
          AND c.customer_state = ts.state
          AND o.order_status = 'delivered'
    )
);

--Восьмой, дополнительный шаг, решает похожую задачу, но уже для продавцов. 
--Мы берём таблицу sellers и применяем к ней ту же самую логику двойного NOT EXISTS, 
--что и во втором шаге. Ищем продавца, для которого не существует штата из множества S, 
--в котором не было бы доставленного заказа с его товарами. По сути находим тех продавцов, 
--которые покрыли заказами все три заданные точки на карте.