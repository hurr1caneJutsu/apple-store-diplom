-- =====================================================
-- БАЗА ДАННЫХ: Apple Store
-- Версия: 3.0
-- СУБД: PostgreSQL
-- =====================================================

-- =====================================================
-- 1. СПРАВОЧНЫЕ ТАБЛИЦЫ
-- =====================================================

-- Таблица категорий товаров
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL
);

COMMENT ON TABLE categories IS 'Категории товаров';

-- Таблица объемов памяти
CREATE TABLE storages (
    storage_id SERIAL PRIMARY KEY,
    capacity   VARCHAR(50) NOT NULL
);

COMMENT ON TABLE storages IS 'Объёмы памяти';

-- Таблица цветов
CREATE TABLE colors (
    color_id SERIAL PRIMARY KEY,
    name     VARCHAR(50) NOT NULL
);

COMMENT ON TABLE colors IS 'Цвета';

-- Таблица поставщиков
CREATE TABLE suppliers (
    supplier_id   SERIAL PRIMARY KEY,
    name          VARCHAR(200) NOT NULL,
    contact_phone VARCHAR(20),
    address       VARCHAR(300),
    inn           VARCHAR(12)  UNIQUE,       -- 10 цифр для юр. лиц, 12 для ИП
    kpp           VARCHAR(9),               -- только для юр. лиц, у ИП отсутствует
    email         VARCHAR(100) UNIQUE,       -- для отправки документов и чеков
    comment       TEXT                      -- произвольные заметки о поставщике
);

COMMENT ON TABLE suppliers IS 'Поставщики';

-- Таблица служб доставки (справочник)
-- Позволяет добавлять новые службы без изменения структуры БД
CREATE TABLE delivery_services (
    service_id SERIAL PRIMARY KEY,
    name       VARCHAR(100) NOT NULL UNIQUE  -- например: 'СДЭК', 'Почта России'
);

COMMENT ON TABLE delivery_services IS 'Службы доставки';

-- =====================================================
-- 2. ТОВАРЫ
-- =====================================================

CREATE TABLE products (
    product_id  SERIAL PRIMARY KEY,
    category_id INTEGER        NOT NULL,
    storage_id  INTEGER        NOT NULL,
    color_id    INTEGER        NOT NULL,
    supplier_id INTEGER        NOT NULL,
    model       VARCHAR(200)   NOT NULL,
    price       DECIMAL(10, 2) NOT NULL CHECK (price > 0),
    quantity    INTEGER        NOT NULL DEFAULT 0 CHECK (quantity >= 0),

    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE RESTRICT,
    FOREIGN KEY (storage_id)  REFERENCES storages(storage_id)    ON DELETE RESTRICT,
    FOREIGN KEY (color_id)    REFERENCES colors(color_id)        ON DELETE RESTRICT,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)  ON DELETE RESTRICT
);

COMMENT ON TABLE products IS 'Товары';

-- =====================================================
-- 3. КЛИЕНТЫ И ЗАКАЗЫ
-- =====================================================

-- full_name разбито на три отдельных поля для корректной нормализации,
-- возможности сортировки по фамилии и корректного обращения к клиенту
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    last_name   VARCHAR(100) NOT NULL,             -- Фамилия
    first_name  VARCHAR(100) NOT NULL,             -- Имя
    patronymic  VARCHAR(100),                      -- Отчество (необязательно)
    phone       VARCHAR(20)  NOT NULL UNIQUE,
    email       VARCHAR(100) UNIQUE                -- необязателен, но уникален если указан
);

COMMENT ON TABLE customers IS 'Клиенты';

-- Таблица заказов
-- delivery_type: 'pickup'   — самовывоз / оплата и получение в магазине
--                'delivery' — доставка курьерской службой
-- payment_type:  'cash'     — наличные
--                'card'     — банковская карта
--                'transfer' — банковский перевод
-- status:        'pending'   — заказ создан, ожидает обработки
--                'confirmed' — заказ собран, передан в доставку или готов к выдаче
--                'completed' — получен и оплачен клиентом
--                'cancelled' — отменён
CREATE TABLE orders (
    order_id      SERIAL PRIMARY KEY,
    customer_id   INTEGER        NOT NULL,
    order_date    DATE           NOT NULL DEFAULT CURRENT_DATE,
    total_amount  DECIMAL(10, 2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    delivery_type VARCHAR(10)    NOT NULL DEFAULT 'pickup'
                                 CHECK (delivery_type IN ('pickup', 'delivery')),
    payment_type  VARCHAR(10)    NOT NULL DEFAULT 'cash'
                                 CHECK (payment_type IN ('cash', 'card', 'transfer')),
    status        VARCHAR(20)    NOT NULL DEFAULT 'pending'
                                 CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled')),

    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT
);

COMMENT ON TABLE orders IS 'Заказы';

-- Таблица состава заказа
CREATE TABLE orders_products (
    order_product_id SERIAL PRIMARY KEY,
    order_id         INTEGER        NOT NULL,
    product_id       INTEGER        NOT NULL,
    quantity         INTEGER        NOT NULL CHECK (quantity > 0),
    price_at_sale    DECIMAL(10, 2) NOT NULL CHECK (price_at_sale > 0),
    serial_number    VARCHAR(100) UNIQUE,         -- серийный номер устройства; уникален, нужен для гарантии и возвратов

    FOREIGN KEY (order_id)   REFERENCES orders(order_id)     ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT
);

COMMENT ON TABLE orders_products IS 'Состав заказов';

-- =====================================================
-- 4. ДОСТАВКА
-- =====================================================

-- Запись создаётся только для заказов с delivery_type = 'delivery' (контролируется триггером).
-- Трек-номер и статус вносит менеджер вручную.
-- Статусы доставки независимы от статуса заказа:
--   'pending'   — доставка ещё не оформлена
--   'shipped'   — передано в службу доставки, трек-номер получен
--   'delivered' — клиент получил заказ
--   'returned'  — посылка возвращена отправителю
CREATE TABLE deliveries (
    delivery_id     SERIAL PRIMARY KEY,
    order_id        INTEGER      NOT NULL UNIQUE,  -- один заказ = одна доставка
    service_id      INTEGER      NOT NULL,
    address         VARCHAR(300) NOT NULL,
    tracking_number VARCHAR(100),                  -- вносится менеджером после передачи в службу
    status          VARCHAR(20)  NOT NULL DEFAULT 'pending'
                                 CHECK (status IN ('pending', 'shipped', 'delivered', 'returned')),
    created_at      DATE         NOT NULL DEFAULT CURRENT_DATE,
    delivered_at    DATE,                          -- фактическая дата получения, вносится менеджером

    FOREIGN KEY (order_id)   REFERENCES orders(order_id)              ON DELETE RESTRICT,
    FOREIGN KEY (service_id) REFERENCES delivery_services(service_id) ON DELETE RESTRICT,

    -- Если доставка завершена, дата получения обязательна
    CONSTRAINT chk_delivered_at CHECK (
        (status = 'delivered' AND delivered_at IS NOT NULL) OR
        (status <> 'delivered')
    ),
    -- Трек-номер обязателен при статусе 'shipped' и выше
    CONSTRAINT chk_tracking_number CHECK (
        (status IN ('shipped', 'delivered', 'returned') AND tracking_number IS NOT NULL) OR
        (status = 'pending')
    )
);

COMMENT ON TABLE deliveries IS 'Доставки';

-- =====================================================
-- 5. ВОЗВРАТЫ
-- =====================================================

-- Возврат привязан к конкретной позиции заказа (order_product_id),
-- что гарантирует невозможность вернуть товар, которого не было в заказе.
-- Контроль количества и суммы возврата обеспечивается триггерами.
CREATE TABLE returns (
    return_id        SERIAL PRIMARY KEY,
    order_product_id INTEGER        NOT NULL,
    quantity         INTEGER        NOT NULL CHECK (quantity > 0),
    return_date      DATE           NOT NULL DEFAULT CURRENT_DATE,
    refund_amount    DECIMAL(10, 2) NOT NULL CHECK (refund_amount > 0),
    reason           VARCHAR(200)   NOT NULL,

    FOREIGN KEY (order_product_id) REFERENCES orders_products(order_product_id) ON DELETE RESTRICT
);

COMMENT ON TABLE returns IS 'Возвраты';

-- =====================================================
-- 6. ИНДЕКСЫ
-- =====================================================

CREATE INDEX idx_products_category        ON products(category_id);
CREATE INDEX idx_products_supplier        ON products(supplier_id);
CREATE INDEX idx_orders_customer          ON orders(customer_id);
CREATE INDEX idx_orders_date              ON orders(order_date);
CREATE INDEX idx_orders_status            ON orders(status);
CREATE INDEX idx_orders_delivery_type     ON orders(delivery_type);
CREATE INDEX idx_orders_products_order    ON orders_products(order_id);
CREATE INDEX idx_orders_products_product  ON orders_products(product_id);
CREATE INDEX idx_deliveries_order         ON deliveries(order_id);
CREATE INDEX idx_deliveries_status        ON deliveries(status);
CREATE INDEX idx_returns_order_product    ON returns(order_product_id);

-- =====================================================
-- 7. ТРИГГЕРЫ
-- =====================================================

-- -------------------------------------------------------
-- Триггер 1: Автоматический пересчёт суммы заказа.
-- Срабатывает при добавлении, изменении или удалении
-- строки в orders_products.
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION update_order_total()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE orders
    SET total_amount = (
        SELECT COALESCE(SUM(quantity * price_at_sale), 0)
        FROM orders_products
        WHERE order_id = COALESCE(NEW.order_id, OLD.order_id)
    )
    WHERE order_id = COALESCE(NEW.order_id, OLD.order_id);

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_order_total
    AFTER INSERT OR UPDATE OR DELETE ON orders_products
    FOR EACH ROW
    EXECUTE FUNCTION update_order_total();

-- -------------------------------------------------------
-- Триггер 2: Управление остатком товара на складе.
-- INSERT — списывает количество.
-- DELETE — возвращает количество.
-- UPDATE — корректирует разницу.
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION update_product_quantity()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF (SELECT quantity FROM products WHERE product_id = NEW.product_id) < NEW.quantity THEN
            RAISE EXCEPTION 'Недостаточно товара на складе (product_id = %)', NEW.product_id;
        END IF;
        UPDATE products
        SET quantity = quantity - NEW.quantity
        WHERE product_id = NEW.product_id;

    ELSIF TG_OP = 'DELETE' THEN
        UPDATE products
        SET quantity = quantity + OLD.quantity
        WHERE product_id = OLD.product_id;

    ELSIF TG_OP = 'UPDATE' THEN
        IF (SELECT quantity FROM products WHERE product_id = NEW.product_id)
            < (NEW.quantity - OLD.quantity) THEN
            RAISE EXCEPTION 'Недостаточно товара на складе (product_id = %)', NEW.product_id;
        END IF;
        UPDATE products
        SET quantity = quantity - (NEW.quantity - OLD.quantity)
        WHERE product_id = NEW.product_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_product_quantity
    BEFORE INSERT OR UPDATE OR DELETE ON orders_products
    FOR EACH ROW
    EXECUTE FUNCTION update_product_quantity();

-- -------------------------------------------------------
-- Триггер 3: Контроль количества при возврате.
-- Сумма возвращённых единиц не может превышать
-- количество купленных по данной позиции заказа.
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION check_return_quantity()
RETURNS TRIGGER AS $$
DECLARE
    purchased_qty INTEGER;
    returned_qty  INTEGER;
BEGIN
    SELECT quantity INTO purchased_qty
    FROM orders_products
    WHERE order_product_id = NEW.order_product_id;

    SELECT COALESCE(SUM(quantity), 0) INTO returned_qty
    FROM returns
    WHERE order_product_id = NEW.order_product_id
      AND return_id IS DISTINCT FROM NEW.return_id;

    IF (returned_qty + NEW.quantity) > purchased_qty THEN
        RAISE EXCEPTION
            'Количество возврата (%) превышает купленное количество (%) для позиции заказа %',
            returned_qty + NEW.quantity, purchased_qty, NEW.order_product_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_return_quantity
    BEFORE INSERT OR UPDATE ON returns
    FOR EACH ROW
    EXECUTE FUNCTION check_return_quantity();

-- -------------------------------------------------------
-- Триггер 4: Контроль типа заказа при создании доставки.
-- Запись в deliveries можно создать только для заказа
-- с delivery_type = 'delivery'.
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION check_delivery_type()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT delivery_type FROM orders WHERE order_id = NEW.order_id) <> 'delivery' THEN
        RAISE EXCEPTION
            'Нельзя создать доставку для заказа с типом "pickup" (order_id = %)', NEW.order_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_delivery_type
    BEFORE INSERT ON deliveries
    FOR EACH ROW
    EXECUTE FUNCTION check_delivery_type();

-- -------------------------------------------------------
-- Триггер 5: Проверка статуса заказа при возврате.
-- Возврат можно оформить только по завершённому заказу
-- (status = 'completed').
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION check_order_status_for_return()
RETURNS TRIGGER AS $$
DECLARE
    v_status VARCHAR(20);
BEGIN
    SELECT o.status INTO v_status
    FROM orders o
    JOIN orders_products op ON op.order_id = o.order_id
    WHERE op.order_product_id = NEW.order_product_id;

    IF v_status <> 'completed' THEN
        RAISE EXCEPTION
            'Возврат невозможен: заказ не завершён (статус: %)', v_status;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_order_status_for_return
    BEFORE INSERT ON returns
    FOR EACH ROW
    EXECUTE FUNCTION check_order_status_for_return();

-- -------------------------------------------------------
-- Триггер 6: Контроль суммы возврата.
-- refund_amount не может превышать фактически уплаченную
-- сумму за возвращаемую позицию (price_at_sale × quantity).
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION check_refund_amount()
RETURNS TRIGGER AS $$
DECLARE
    max_refund DECIMAL(10, 2);
BEGIN
    SELECT price_at_sale * NEW.quantity INTO max_refund
    FROM orders_products
    WHERE order_product_id = NEW.order_product_id;

    IF NEW.refund_amount > max_refund THEN
        RAISE EXCEPTION
            'Сумма возврата (%) превышает максимально возможную (%) для позиции заказа %',
            NEW.refund_amount, max_refund, NEW.order_product_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_refund_amount
    BEFORE INSERT OR UPDATE ON returns
    FOR EACH ROW
    EXECUTE FUNCTION check_refund_amount();
