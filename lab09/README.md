## Практическая работа № 9. Функциональные зависимости и нормализация
Цель работы. Научиться выводить функциональные зависимости из бизнес-правил, находить ключи и декомпозировать отношение до 3НФ/НФБК.
Вар.	Исходное отношение	Бизнес-правила для вывода ФЗ
6	delivery_flat(shipment_id, order_id, seller_id, seller_city, attempt_no, attempt_time, event_code, event_name)	
                                shipment → order,seller; seller → city; event_code → event_name; (shipment,attempt_no) → attempt_time.

Общая обязательная часть:
1. Для отношения своего варианта переписать бизнес-правила как набор функциональных зависимостей.
2. Найти минимум один потенциальный ключ через замыкание атрибутов.
3. Указать частичные и транзитивные зависимости, если они существуют.
4. Описать минимум по одной аномалии INSERT, UPDATE и DELETE исходной плоской таблицы.
5. Провести декомпозицию последовательно до 3НФ. Для каждого шага указать, какая зависимость стала причиной разбиения.
6. Проверить, можно ли получить НФБК без потери важных зависимостей.
7. Реализовать итоговые отношения как lab.nf_<variant>_* в PostgreSQL с PK/FK/UNIQUE.
8. Добавить 3–5 тестовых строк и показать, что ранее дублировавшиеся справочные значения теперь хранятся один раз.
# Практическая работа №9. Вариант 6: Нормализация таблицы доставки

## 1. Исходные данные и функциональные зависимости (ФЗ)
Исходная плоская таблица: 
`delivery_flat(shipment_id, order_id, seller_id, seller_city, attempt_no, attempt_time, event_code, event_name)`

Набор функциональных зависимостей (строго по методичке):
1. `shipment_id → order_id, seller_id`
2. `seller_id → seller_city`
3. `event_code → event_name`
4. `(shipment_id, attempt_no) → attempt_time`

## 2. Поиск ключа и замыкание
Ищем замыкание атрибутов. Поскольку `event_code` не определяется ни одной зависимостью, он должен входить в ключ.
Проверяем замыкание `{shipment_id, attempt_no, event_code}+`:
- `shipment_id` → находим `order_id`, `seller_id`.
- `seller_id` → находим `seller_city`.
- `event_code` → находим `event_name`.
- `(shipment_id, attempt_no)` → находим `attempt_time`.

**Вывод:** Замыкание содержит все атрибуты таблицы. **`{shipment_id, attempt_no, event_code}` — это минимальный потенциальный ключ**.

## 3. Аномалии исходной таблицы
Если хранить всё в одной таблице, возникнут проблемы:
- **INSERT (вставка):** Мы не сможем добавить в базу новый город продавца или новое название события, пока не появится хотя бы одна реальная доставка (иначе не будет первичного ключа).
- **UPDATE (обновление):** Если продавец переедет в другой город, придется менять поле `seller_city` во всех тысячах строк, где он упоминается.
- **DELETE (удаление):** Если мы удалим все доставки конкретного продавца, мы случайно удалим и информацию о том, в каком городе он находится.

## 4. Шаги нормализации (Декомпозиция до 3НФ)
Частичные (зависят от части составного ключа):
   shipment_id → order_id, seller_id
Транзитивные (цепочка через неключевой атрибут):
  shipment_id → seller_id → seller_city
  event_code → event_name
**Шаг 1. Устраняем частичные зависимости (приводим ко 2НФ)**
Атрибуты `order_id` и `seller_id` зависят только от части ключа (`shipment_id`). Выносим их в отдельную таблицу.
- Таблица 1: `Shipments(shipment_id, order_id, seller_id)`
- Таблица 2: `Attempts(shipment_id, attempt_no, attempt_time, event_code, event_name)`

**Шаг 2. Устраняем транзитивные зависимости (приводим к 3НФ)**
В таблице `Shipments` город продавца зависит не от ключа, а от `seller_id`. Выносим продавцов в справочник.
В таблице `Attempts` название события зависит от `event_code`. Выносим события в справочник.

**Итоговые таблицы (3НФ):**
1. `Sellers(seller_id, seller_city)` — *Справочник продавцов*
2. `Events(event_code, event_name)` — *Справочник событий*
3. `Shipments(shipment_id, order_id, seller_id)` — *Отправления*
4. `Attempts(shipment_id, attempt_no, attempt_time, event_code)` — *Попытки доставки*

## 5. Проверка получения НФБК без потери важных зависимостей.
Проверяем наши таблицы:
Sellers: seller_id → seller_city — детерминант seller_id является PK
Events: event_code → event_name — детерминант event_code является PK
Shipments: shipment_id → order_id, seller_id — детерминант shipment_id является PK
Attempts: (shipment_id, attempt_no, event_code) → attempt_time — детерминант является PK

Вывод: Все таблицы уже в НФБК. Потери зависимостей нет.

--6. Реализовать итоговые отношения как lab.nf_<variant>_* в PostgreSQL с PK/FK/UNIQUE.



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

--7. Добавить 3–5 тестовых строк и показать, что ранее дублировавшиеся справочные значения теперь хранятся один раз.

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
