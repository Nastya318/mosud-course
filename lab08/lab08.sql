--Практическая работа № 8. ER-модель и расширение предметной области (вариант 6)
CREATE SCHEMA IF NOT EXISTS lab;
--2. Создать в схеме lab не менее трёх новых таблиц. Минимум две таблицы должны быть связаны с исходными объектами Olist внешними ключами.
--3. Использовать минимум: один составной или альтернативный UNIQUE, два CHECK, три NOT NULL и корректные внешние ключи.
--4. Назвать ограничения осмысленно: pk_..., fk_..., ck_..., uq_....
-- 1) Таблица shipments — отправление по заказу
--связана с olist.orders внешним ключом.
CREATE TABLE lab.shipments (
    shipment_id      BIGINT GENERATED ALWAYS AS IDENTITY,
    order_id         CHAR(32)    NOT NULL, -- FK на olist.orders
    shipment_number  VARCHAR(40) NOT NULL, -- трекинг-номер (альтернативный ключ)
    carrier_name     VARCHAR(80) NOT NULL,-- перевозчик
    shipped_at       TIMESTAMP   NOT NULL, -- дата отгрузки
    delivered_at     TIMESTAMP,     -- может быть NULL, если ещё не доставлено
    status           VARCHAR(20) NOT NULL,

    -- первичный ключ
    CONSTRAINT pk_shipments PRIMARY KEY (shipment_id),

    -- альтернативный ключ: трекинг-номер уникален
    CONSTRAINT uq_shipments_number UNIQUE (shipment_number),

    -- CHECK: статус только из допустимого списка
    CONSTRAINT ck_shipments_status
        CHECK (status IN ('pending', 'in_transit', 'delivered', 'failed')),

    -- CHECK: delivered_at заполняется только при статусе 'delivered'
    CONSTRAINT ck_shipments_delivered_at
        CHECK (
            (status = 'delivered' AND delivered_at IS NOT NULL) OR
            (status <> 'delivered' AND delivered_at IS NULL)
        ),

    -- внешний ключ на исходную таблицу Olist
    CONSTRAINT fk_shipments_order
        FOREIGN KEY (order_id) REFERENCES olist.orders(order_id)
);

-- 2) Таблица delivery_attempts — попытка доставки
--Связана с shipments.
CREATE TABLE lab.delivery_attempts (
    attempt_id       BIGINT GENERATED ALWAYS AS IDENTITY,
    shipment_id      BIGINT      NOT NULL, -- FK на shipments
    attempt_number   SMALLINT    NOT NULL,  -- номер попытки (1, 2, 3...)
    attempted_at     TIMESTAMP   NOT NULL,  -- когда пытались
    outcome          VARCHAR(20) NOT NULL,  -- результат
    notes            TEXT,  -- комментарий курьера

    CONSTRAINT pk_delivery_attempts PRIMARY KEY (attempt_id),

    -- составной альтернативный ключ: в рамках одной отправки номер попытки уникален
    CONSTRAINT uq_attempts_shipment_number UNIQUE (shipment_id, attempt_number),

    -- CHECK: результат только из списка
    CONSTRAINT ck_attempts_outcome
        CHECK (outcome IN ('success', 'failed', 'rescheduled')),

    -- CHECK: номер попытки положительный
    CONSTRAINT ck_attempts_number
        CHECK (attempt_number > 0),

    CONSTRAINT fk_attempts_shipment
        FOREIGN KEY (shipment_id) REFERENCES lab.shipments(shipment_id)
            ON DELETE CASCADE
);

-- 3) Таблица delivery_events — события внутри попытки
--    Связана с delivery_attempts.
CREATE TABLE lab.delivery_events (
    event_id         BIGINT GENERATED ALWAYS AS IDENTITY,
    attempt_id       BIGINT       NOT NULL,              -- FK на delivery_attempts
    event_type       VARCHAR(30)  NOT NULL,        -- тип события
    event_timestamp  TIMESTAMP    NOT NULL,      -- когда произошло
    location         VARCHAR(120),                 -- где (город/адрес)
    description      TEXT,                             -- детали

    CONSTRAINT pk_delivery_events PRIMARY KEY (event_id),

    -- CHECK: допустимые типы событий
    CONSTRAINT ck_events_type
        CHECK (event_type IN ('picked_up', 'in_transit', 'out_for_delivery',
                              'delivered', 'failed', 'rescheduled')),

    CONSTRAINT fk_events_attempt
        FOREIGN KEY (attempt_id) REFERENCES lab.delivery_attempts(attempt_id)
            ON DELETE CASCADE
);


--5. Заполнить каждую новую таблицу минимум пятью тестовыми строками, используя реальные order_id/product_id/seller_id из Olist.
-- 5 строк в shipments
SELECT order_id FROM olist.orders LIMIT 5;

INSERT INTO lab.shipments
    (order_id, shipment_number, carrier_name, shipped_at, delivered_at, status)
VALUES
    ('e481f51cbdc54678b7cc49136f2d6af7', 'BR100000001', 'Correios',   '2026-10-01 10:00:00', '2026-10-03 14:20:00', 'delivered'),
    ('53cdb2fc8bc7dce0b6741e2150273451', 'BR100000002', 'Jadlog',     '2026-10-02 09:15:00', NULL,                  'in_transit'),
    ('47770eb9100c2d0c44946d9cf07ec65d', 'BR100000003', 'Correios',   '2026-10-03 11:40:00', NULL,                  'pending'),
    ('949d5b44dbf5de918fe9c16f97b45f8a', 'BR100000004', 'Loggi',      '2026-10-04 08:00:00', '2026-10-05 17:55:00', 'delivered'),
    ('949d5b44dbf5de918fe9c16f97b45f8a', 'BR100000005', 'Jadlog',     '2026-10-05 13:30:00', NULL,                  'failed');

-- 5 строк в delivery_attempts
INSERT INTO lab.delivery_attempts
    (shipment_id, attempt_number, attempted_at, outcome, notes)
VALUES
    (1, 1, '2026-10-03 14:20:00', 'success',    'Вручено лично получателю'),
    (2, 1, '2026-10-04 10:00:00', 'failed',     'Адресат не найден'),
    (2, 2, '2026-10-05 11:30:00', 'rescheduled','Перенесено на следующий день'),
    (3, 1, '2026-10-06 09:00:00', 'failed',     'Нет доступа в офис'),
    (4, 1, '2026-10-05 17:55:00', 'success',    'Оставлено у консьержа');

-- 5 строк в delivery_events
INSERT INTO lab.delivery_events
    (attempt_id, event_type, event_timestamp, location, description)
VALUES
    (1, 'picked_up',      '2026-10-01 10:30:00', 'São Paulo SP', 'Забрано со склада'),
    (1, 'in_transit',     '2026-10-02 06:15:00', 'Campinas SP',  'В пути'),
    (1, 'out_for_delivery','2026-10-03 08:00:00', 'São Paulo SP', 'Передано курьеру'),
    (1, 'delivered',      '2026-10-03 14:20:00', 'São Paulo SP', 'Вручено'),
    (2, 'failed',         '2026-10-04 10:00:00', 'Rio de Janeiro RJ', 'Адресат отсутствует');

select * from lab.shipments;
select * from lab.delivery_attempts;
select * from lab.delivery_events;

--6. Подготовить минимум три ошибочных INSERT/UPDATE в комментариях и объяснить, какое ограничение должно их отклонить.
--Ошибка 1: нарушен CHECK по статусу
--должно отклонить ограничение: ck_shipments_status
INSERT INTO lab.shipments
  (order_id, shipment_number, carrier_name, shipped_at, delivered_at, status)
VALUES
     ('0001024310b7bf7a7a0f03a3f6c8b8e4', 'BR999999999', 'Correios',
      '2026-10-10 10:00:00', NULL, 'lost');

-- Ошибка 2: нарушен CHECK согласованности delivered_at и status
--статус "delivered", но delivered_at = NULL
--должно отклонить ограничение: ck_shipments_delivered_at
 INSERT INTO lab.shipments
     (order_id, shipment_number, carrier_name, shipped_at, delivered_at, status)
 VALUES
     ('0001024310b7bf7a7a0f03a3f6c8b8e4', 'BR888888888', 'Jadlog',
      '2026-10-10 10:00:00', NULL, 'delivered');

-- Ошибка 3: нарушен составной UNIQUE (shipment_id, attempt_number)
--для shipment_id = 2 уже есть attempt_number = 1 и 2, вставляем ещё одну 2
--должно отклонить ограничение: uq_attempts_shipment_number
INSERT INTO lab.delivery_attempts
     (shipment_id, attempt_number, attempted_at, outcome, notes)
VALUES
     (2, 2, '2026-10-06 12:00:00', 'success', 'Дубликат попытки');

-- Ошибка 4: нарушен внешний ключ — shipment_id = 9999 не существует
-- Должно отклонить ограничение: fk_attempts_shipment
INSERT INTO lab.delivery_attempts
     (shipment_id, attempt_number, attempted_at, outcome, notes)
 VALUES
     (9999, 1, '2026-10-06 12:00:00', 'success', 'Несуществующая отправка');

--7. Проверить схему запросом к information_schema или pg_catalog.

--список таблиц схемы lab
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'lab'
ORDER BY table_name;

--столбцы, типы и NULL-признак
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'lab'
ORDER BY table_name, ordinal_position;

--все ограничения (PK, FK, UNIQUE, CHECK)
SELECT tc.table_name, tc.constraint_name, tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.constraint_schema = 'lab'
ORDER BY tc.table_name, tc.constraint_type;

