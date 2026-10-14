--практическая 3
--  отношение                  предикат                               проекция
--6	order_reviews	review_score ≤ 2 и comment_message IS NOT NULL	order_id, score, comment_message




SELECT 
    order_id, 
    review_score, 
    review_comment_message
FROM olist.order_reviews
WHERE review_score <= 2 
  AND review_comment_message IS NOT NULL;

SELECT count (*) as кол_во
FROM olist.order_reviews
WHERE review_score <= 2 
  AND review_comment_message IS NOT NULL;

-- 4. Разбить сложный предикат на две последовательные выборки
-- Сначала фильтруем по оценке, потом по наличию комментария.

WITH step1 AS (
    SELECT *
    FROM olist.order_reviews
    WHERE review_score <= 2
),
step2 AS (
    -- Вторая выборка: из них оставляем только те, где есть комментарий
    SELECT *
    FROM step1
    WHERE review_comment_message IS NOT NULL
)
SELECT 
    order_id, 
    review_score, 
    review_comment_message
FROM step2;


WITH step1 AS (
    SELECT *
    FROM olist.order_reviews
    WHERE review_score <= 2
),
step2 AS (
    SELECT *
    FROM step1
    WHERE review_comment_message IS NOT NULL
)
select count(*) as total
FROM step2;


-- 5. Второй SQL-вариант: исключаем ненужные столбцы раньше
--Сначала делаем проекцию (оставляем только 3 нужных столбца), потом применяем фильтрацию. Это снижает объём данных для обработки.

WITH projected AS (
    --сначала проекция — оставляем только нужные атрибуты
    SELECT 
        order_id, 
        review_score, 
        review_comment_message
    FROM olist.order_reviews
)
SELECT count(*)
FROM projected
WHERE review_score <= 2 
  AND review_comment_message IS NOT NULL;



-- 6. Проверка дубликатов в проекции

--обычный SELECT (может содержать дубликаты)
SELECT 
    order_id, 
    review_score, 
    review_comment_message
FROM olist.order_reviews
WHERE review_score <= 2 
  AND review_comment_message IS NOT NULL;

-- SELECT DISTINCT (удаляет дубликаты)
SELECT DISTINCT
    order_id, 
    review_score, 
    review_comment_message
FROM olist.order_reviews
WHERE review_score <= 2 
  AND review_comment_message IS NOT NULL;

--сравниваем количество строк
SELECT 
    'SELECT' AS вариант, count(*) AS строк
FROM (
    SELECT order_id, review_score, review_comment_message
    FROM olist.order_reviews
    WHERE review_score <= 2 AND review_comment_message IS NOT NULL
) t

UNION ALL

SELECT 
    'SELECT DISTINCT', count(*)
FROM (
    SELECT DISTINCT order_id, review_score, review_comment_message
    FROM olist.order_reviews
    WHERE review_score <= 2 AND review_comment_message IS NOT NULL
) t;