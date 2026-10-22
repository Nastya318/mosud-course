
-- Практическая работа № 7. NULL, трёхзначная логика и качество данных


--1. Для orders, products и order_reviews подсчитать число NULL по всем потенциально необязательным столбцам.
SELECT 'orders' AS table_name,
       SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS null_delivered_date,
       SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS null_carrier_date
FROM olist.orders
UNION ALL
SELECT 'products',
       SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END),
       SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END)
FROM olist.products
UNION ALL
SELECT 'order_reviews',
       SUM(CASE WHEN review_comment_title IS NULL THEN 1 ELSE 0 END),
       SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END)
FROM olist.order_reviews;


--2. Сравнить COUNT (*) и COUNT (order_delivered_customer_date) и объяснить разницу.

SELECT 
    COUNT(*) AS total_rows, 
    COUNT(order_delivered_customer_date) AS non_null_dates 
FROM olist.orders;

-- COUNT обрабатывает все тсроки, считая null

--3. Показать, что = NULL и <> NULL не возвращают ожидаемых строк; исправить через IS NULL/IS NOT NULL.
-- Ошибочный способ: эти запросы всегда вернут 0 строк
SELECT COUNT(*) AS wrong_equals_null FROM olist.orders WHERE order_delivered_customer_date = NULL;
SELECT COUNT(*) AS wrong_not_equals_null FROM olist.orders WHERE order_delivered_customer_date <> NULL;

-- Правильный способ
SELECT COUNT(*) AS correct_is_null FROM olist.orders WHERE order_delivered_customer_date IS NULL;
SELECT COUNT(*) AS correct_is_not_null FROM olist.orders WHERE order_delivered_customer_date IS NOT NULL;


--4. Продемонстрировать IS DISTINCT FROM на двух значениях, одно из которых может быть NULL.

SELECT 
    order_id,
    order_delivered_customer_date,
    --cравнение с конкретной датой. Если дата NULL, результат будет TRUE
    (order_delivered_customer_date IS DISTINCT FROM '2018-01-01') AS is_distinct_demo
FROM olist.orders
LIMIT 10;

--Если дата доставки равна NULL (заказ не доставлен), обычное сравнение NULL <> '2018-01-01' вернуло бы UNKNOWN,
--а IS DISTINCT FROM вернет TRUE, так как "отсутствие даты" и "конкретная дата" — это определенно разные вещи.
--Запрос берет первые 10 строк из таблицы заказов и сравнивает дату доставки каждого заказа с конкретной датой '2018-01-01'. 
--В отдельном столбце is_distinct_demo выводится результат этого сравнения.

----5. Создать временную таблицу temp_ids(id text), добавить существующий order_id и NULL. Сравнить NOT IN и NOT EXISTS.

-- Создаем временную таблицу и добавляем один существующий order_id и один NULL
CREATE TEMP TABLE temp_ids (id TEXT);
INSERT INTO temp_ids (id) SELECT order_id FROM olist.orders LIMIT 1;
INSERT INTO temp_ids (id) VALUES (NULL);

-- NOT IN: из-за наличия NULL в подзапросе этот запрос вернет 0 строк (ловушка!)
SELECT COUNT(*) AS not_in_count FROM olist.orders WHERE order_id NOT IN (SELECT id FROM temp_ids);

-- NOT EXISTS: корректно отфильтрует только тот один заказ, который есть в таблице
SELECT COUNT(*) AS not_exists_count FROM olist.orders o WHERE NOT EXISTS (SELECT 1 FROM temp_ids t WHERE t.id = o.order_id);

-- Удаляем временную таблицу
DROP TABLE temp_ids;



--6. Составить два запроса с LEFT JOIN reviews: в первом фильтр review_score ≥ 4 разместить в ON, во втором — в WHERE.
-- Сравнить число заказов и объяснить семантику.
-- Фильтр в ON: сохраняет все заказы, даже если у них нет отзыва с оценкой >= 4
SELECT COUNT(DISTINCT o.order_id) AS orders_with_on_filter
FROM olist.orders o
LEFT JOIN olist.order_reviews r ON o.order_id = r.order_id AND r.review_score >= 4;

-- Фильтр в WHERE: отбрасывает заказы, у которых нет подходящего отзыва (превращает LEFT JOIN в INNER)
SELECT COUNT(DISTINCT o.order_id) AS orders_with_where_filter
FROM olist.orders o
LEFT JOIN olist.order_reviews r ON o.order_id = r.order_id
WHERE r.review_score >= 4 OR r.review_score IS NULL; 

--первое - то значит, что база берет все заказы (левую таблицу), а отзывы подтягивает только хорошие. 
--Если у заказа нет хорошего отзыва, он все равно остается в выборке, просто с пустыми значениями (NULL) в полях отзыва.

--второе - Во втором запросе условие вынесено в WHERE, но туда добавлена страховка OR r.review_score IS NULL. 
--Если бы этой страховки не было, WHERE отбросил бы все заказы без хороших отзывов (потому что NULL — это не >= 4). 
--Благодаря OR ... IS NULL запрос сохраняет заказы без отзывов, но всё равно отсеивает заказы, у которых есть отзыв, но с низкой оценкой. 

-- --7. Использовать COALESCE для текстового комментария и NULLIF для безопасного деления.
SELECT 
    o.order_id,
    -- COALESCE берет комментарий из таблицы отзывов и заменяет NULL на текст
    COALESCE(r.review_comment_message, 'Текст комментария отсутствует') AS safe_comment,
    -- NULLIF защищает от деления на ноль в таблице платежей
    p.payment_value / NULLIF(p.payment_installments, 0) AS safe_division
FROM olist.orders o
LEFT JOIN olist.order_reviews r ON o.order_id = r.order_id
JOIN olist.order_payments p ON o.order_id = p.order_id
LIMIT 10;


--8. Сформировать мини-профиль качества: доля заказов без фактической даты доставки, доля товаров без категории, доля отзывов без текста.

SELECT 
    ROUND(100.0 * SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_orders_no_delivery_date,
    (SELECT ROUND(100.0 * SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) FROM olist.products) AS pct_products_no_category,
    (SELECT ROUND(100.0 * SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) FROM olist.order_reviews) AS pct_reviews_no_text
FROM olist.orders;

--считает три процентных показателя, чтобы оценить качество данных.
-- В основной таблице заказов он считает, у какой доли заказов нет даты фактической доставки. 
--Затем с помощью подзапросов он отдельно заглядывает в таблицу товаров и считает долю товаров без указанной категории, 
--а также в таблицу отзывов — чтобы узнать долю отзывов без текста. 
--Все результаты округляются до двух знаков и выводятся как проценты от общего числа строк в каждой таблице.


--9. Найти столбец, где NULL является естественным состоянием, и столбец, где NULL скорее указывает на проблему качества данных. Обосновать.
-- Запрос для обоснования (считаем доли NULL)
SELECT 
    'review_comment_message (Естественный NULL)' AS column_type,
    ROUND(100.0 * SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS null_percentage
FROM olist.order_reviews
UNION ALL
SELECT 
    'product_category_name (Проблема качества)',
    ROUND(100.0 * SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2)
FROM olist.products;

--создает таблицу из двух строк для наглядного сравнения. 
--Он объединяет (UNION ALL) два независимых подсчета: 
--в первом вычисляется процент пустых комментариев в таблице отзывов (чтобы показать, что отсутствие текста — это нормально, 
--люди часто ставят оценку без слов), а во втором — процент товаров без категории (что является ошибкой заполнения карточки товара).