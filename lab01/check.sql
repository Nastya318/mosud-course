-- Подсчёт строк в основных таблицах
SELECT 'customers' AS table_name, count(*) FROM olist.customers 
UNION ALL 
SELECT 'orders', count(*) FROM olist.orders 
UNION ALL 
SELECT 'order_items', count(*) FROM olist.order_items
UNION ALL
SELECT 'order_payments', count(*) FROM olist.order_payments
UNION ALL
SELECT 'order_reviews', count(*) FROM olist.order_reviews
UNION ALL
SELECT 'products', count(*) FROM olist.products
UNION ALL
SELECT 'sellers', count(*) FROM olist.sellers
UNION ALL
SELECT 'geolocation', count(*) FROM olist.geolocation
UNION ALL
SELECT 'product_category_name_translation', count(*) FROM olist.product_category_name_translation;

-- Проверка на "осиротевшие" записи (должно быть 0)
SELECT count(*) AS orphan_items 
FROM olist.order_items oi 
LEFT JOIN olist.orders o ON o.order_id = oi.order_id 
WHERE o.order_id IS NULL;

-- Проверка на NULL в первичных ключах (должно быть 0)
SELECT count(*) AS null_customers FROM olist.customers WHERE customer_id IS NULL;
SELECT count(*) AS null_orders FROM olist.orders WHERE order_id IS NULL;

-- Обновление статистики
ANALYZE olist.customers;
ANALYZE olist.orders;
ANALYZE olist.order_items;
ANALYZE olist.order_payments;
ANALYZE olist.order_reviews;
ANALYZE olist.products;
ANALYZE olist.sellers;
ANALYZE olist.geolocation;
ANALYZE olist.product_category_name_translation;