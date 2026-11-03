Бизнес-правила и ограничения:

1. У каждого отправления есть уникальный трекинг-номер
Ограничение: uq_shipments_tracking (UNIQUE на поле tracking_number)
2. Отправление не может существовать без заказа
Ограничение: fk_shipments_order (FOREIGN KEY на olist.orders.order_id)
3. Отправление не может существовать без продавца
Ограничение: fk_shipments_seller (FOREIGN KEY на olist.sellers.seller_id)
4. Статус отправления может быть только: pending, in_transit, delivered или failed
Ограничение: ck_shipments_status (CHECK)
5. Поле delivered_at заполняется только при статусе delivered
Ограничение: ck_shipments_delivered_at (CHECK)
6. Перевозчик и дата отгрузки обязательны для каждого отправления
Ограничение: NOT NULL на полях carrier_name и shipped_at
7. Номер попытки доставки — положительное число
Ограничение: ck_attempts_number (CHECK attempt_number > 0)
8. В рамках одной отправки номер попытки уникален
Ограничение: uq_attempts_shipment_number (составной UNIQUE на shipment_id и attempt_number)
9. Результат попытки может быть только: success, failed или rescheduled
Ограничение: ck_attempts_outcome (CHECK)
10. Каждое событие доставки привязано к конкретной попытке
Ограничение: fk_events_attempt (FOREIGN KEY на delivery_attempts.attempt_id)
11. Тип события может быть только из списка: picked_up, in_transit, out_for_delivery, delivered, failed, rescheduled
Ограничение: ck_events_type (CHECK)
12. Время события и местоположение обязательны
Ограничение: NOT NULL на полях event_timestamp и location