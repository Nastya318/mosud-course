--Вар.	   Исходное отношение	           Бизнес-правила для вывода ФЗ
--6	   delivery_flat(shipment_id, order_id, 
--     seller_id, seller_city, attempt_no,
--     attempt_time, event_code, event_name)	
--                                        shipment → order,seller; seller → city; event_code → event_name; (shipment,attempt_no) → attempt_time.

--...
--7. Реализовать итоговые отношения как lab.nf_<variant>_* в PostgreSQL с PK/FK/UNIQUE.



-- 1.Справочник продавцов (устранена транзитивная зависимость seller_id -> seller_city)
CREATE TABLE lab.nf_6_sellers (
    seller_id   VARCHAR(32) PRIMARY KEY,
    seller_city VARCHAR(80) NOT NULL
);

-- 2.Справочник событий (устранена транзитивная зависимость event_code -> event_name)
CREATE TABLE lab.nf_6_events (
    event_code  VARCHAR(30) PRIMARY KEY,
    event_name  VARCHAR(100) NOT NULL
);

-- 3.Таблица отправок (устранена частичная зависимость от shipment_id)
CREATE TABLE lab.nf_6_shipments (
    shipment_id BIGINT PRIMARY KEY,
    order_id    VARCHAR(32) NOT NULL,
    seller_id   VARCHAR(32) NOT NULL,
    CONSTRAINT fk_nf6_ship_seller FOREIGN KEY (seller_id) REFERENCES lab.nf_6_sellers(seller_id)
);

-- 4.Таблица попыток доставки (составной первичный ключ)

CREATE TABLE lab.nf_6_attempts (
    shipment_id  BIGINT NOT NULL,
    attempt_no   SMALLINT NOT NULL,
    event_code   VARCHAR(30) NOT NULL,
    attempt_time TIMESTAMP NOT NULL,
    
    --Составной PK из 3-х атрибутов
    CONSTRAINT pk_nf6_attempts PRIMARY KEY (shipment_id, attempt_no, event_code),
 
    CONSTRAINT fk_nf6_att_ship FOREIGN KEY (shipment_id) REFERENCES lab.nf_6_shipments(shipment_id),
    CONSTRAINT fk_nf6_att_event FOREIGN KEY (event_code) REFERENCES lab.nf_6_events(event_code)
);

--8. Добавить 3–5 тестовых строк и показать, что ранее дублировавшиеся справочные значения теперь хранятся один раз.

--Демонстрация того, что справочные значения хранятся один раз


--Продавцы (города не дублируются, даже если у продавца много отправок)
INSERT INTO lab.nf_6_sellers (seller_id, seller_city) VALUES
    ('S001', 'São Paulo'),
    ('S002', 'Rio de Janeiro'),
    ('S003', 'Curitiba');

--События (названия событий хранятся только здесь)
INSERT INTO lab.nf_6_events (event_code, event_name) VALUES
    ('PU', 'Picked Up'),
    ('IT', 'In Transit'),
    ('OFD', 'Out for Delivery'),
    ('DL', 'Delivered'),
    ('FA', 'Failed Attempt');

--Отправки (ссылаются на продавцов)
INSERT INTO lab.nf_6_shipments (shipment_id, order_id, seller_id) VALUES
    (1001, 'ORD-001', 'S001'),
    (1002, 'ORD-002', 'S001'), --тот же продавец S001, город не дублируется--
    (1003, 'ORD-003', 'S002');

--Попытки доставки (ссылаются на отправки и события)
INSERT INTO lab.nf_6_attempts (shipment_id, attempt_no, attempt_time, event_code) VALUES
    (1001, 1, '2026-10-01 10:00:00', 'PU'),
    (1001, 2, '2026-10-02 14:00:00', 'DL'),
    (1002, 1, '2026-10-03 09:00:00', 'FA'), --неудачная попытка
    (1002, 2, '2026-10-04 11:00:00', 'DL'),
    (1003, 1, '2026-10-05 08:30:00', 'OFD');



--проверка: Демонстрация отсутствия дублирования


-- Посмотрим, как данные выглядят в соединенном виде (как в исходной плоской таблице)
SELECT 
    s.shipment_id, 
    s.order_id, 
    sel.seller_id, 
    sel.seller_city, --город подтягивается из справочника Sellers
    a.attempt_no, 
    a.attempt_time, 
    e.event_code, 
    e.event_name --название события подтягивается из справочника Events
FROM lab.nf_6_attempts a
JOIN lab.nf_6_shipments s ON a.shipment_id = s.shipment_id
JOIN lab.nf_6_sellers sel ON s.seller_id = sel.seller_id
JOIN lab.nf_6_events e ON a.event_code = e.event_code
ORDER BY s.shipment_id, a.attempt_no;

select * from lab.nf_6_sellers;
select * from lab.nf_6_events;