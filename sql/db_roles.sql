-- =====================================================
-- AppStore: Роли, права доступа и ограничения входа
-- Запускать ПОСЛЕ создания структуры БД (apple_store_db_v3.sql)
-- =====================================================


-- =====================================================
-- 1. СОЗДАНИЕ РОЛЕЙ
-- =====================================================

-- Суперпользователь — полный контроль над БД
CREATE ROLE "Суперпользователь" WITH
    LOGIN
    SUPERUSER
    PASSWORD 'super_2026';

-- Менеджер — работает с товарами, заказами, клиентами, доставками, возвратами
CREATE ROLE "Менеджер" WITH
    LOGIN
    NOSUPERUSER
    CONNECTION LIMIT 5
    PASSWORD 'manager_2026';

-- Бухгалтер — только чтение всех таблиц для формирования отчётов
CREATE ROLE "Бухгалтер" WITH
    LOGIN
    NOSUPERUSER
    CONNECTION LIMIT 3
    PASSWORD 'buh_2026';


-- =====================================================
-- 2. ОГРАНИЧЕНИЕ КОЛИЧЕСТВА ПОПЫТОК ВХОДА
-- =====================================================
-- Расширение auth_delay добавляет задержку при неверном пароле.
-- Добавить в postgresql.conf:
--   auth_delay.milliseconds = '3000'
--   authentication_timeout = 10s
-- Задержка 3 секунды делает брутфорс практически невозможным.

CREATE EXTENSION IF NOT EXISTS auth_delay;


-- =====================================================
-- 3. ПРАВА НА СХЕМУ
-- =====================================================

GRANT USAGE ON SCHEMA public TO "Менеджер";
GRANT USAGE ON SCHEMA public TO "Бухгалтер";


-- =====================================================
-- 4. ПРАВА НА ТАБЛИЦЫ
-- =====================================================
-- Матрица доступа:
-- Таблица              | Суперпользователь | Менеджер                    | Бухгалтер
-- ---------------------|-------------------|-----------------------------|----------
-- categories           | ALL               | SELECT, INSERT, UPDATE, DELETE | SELECT
-- colors               | ALL               | SELECT, INSERT, UPDATE, DELETE | SELECT
-- storages             | ALL               | SELECT, INSERT, UPDATE, DELETE | SELECT
-- suppliers            | ALL               | SELECT, INSERT, UPDATE, DELETE | SELECT
-- delivery_services    | ALL               | SELECT, INSERT, UPDATE, DELETE | SELECT
-- products             | ALL               | SELECT, INSERT, UPDATE, DELETE | SELECT
-- customers            | ALL               | SELECT, INSERT, UPDATE, DELETE | SELECT
-- orders               | ALL               | SELECT, INSERT, UPDATE, DELETE | SELECT
-- orders_products      | ALL               | SELECT, INSERT, UPDATE, DELETE | SELECT
-- deliveries           | ALL               | SELECT, INSERT, UPDATE, DELETE | SELECT
-- returns              | ALL               | SELECT, INSERT, UPDATE, DELETE | SELECT

-- ── categories ───────────────────────────────────────────────────────────────
REVOKE ALL ON TABLE public.categories FROM "Менеджер";
REVOKE ALL ON TABLE public.categories FROM "Бухгалтер";
GRANT SELECT, INSERT, UPDATE, DELETE  ON TABLE public.categories TO "Менеджер";
GRANT SELECT                          ON TABLE public.categories TO "Бухгалтер";
GRANT ALL                             ON TABLE public.categories TO "Суперпользователь";
ALTER TABLE public.categories OWNER TO "Суперпользователь";

-- ── colors ────────────────────────────────────────────────────────────────────
REVOKE ALL ON TABLE public.colors FROM "Менеджер";
REVOKE ALL ON TABLE public.colors FROM "Бухгалтер";
GRANT SELECT, INSERT, UPDATE, DELETE  ON TABLE public.colors TO "Менеджер";
GRANT SELECT                          ON TABLE public.colors TO "Бухгалтер";
GRANT ALL                             ON TABLE public.colors TO "Суперпользователь";
ALTER TABLE public.colors OWNER TO "Суперпользователь";

-- ── storages ──────────────────────────────────────────────────────────────────
REVOKE ALL ON TABLE public.storages FROM "Менеджер";
REVOKE ALL ON TABLE public.storages FROM "Бухгалтер";
GRANT SELECT, INSERT, UPDATE, DELETE  ON TABLE public.storages TO "Менеджер";
GRANT SELECT                          ON TABLE public.storages TO "Бухгалтер";
GRANT ALL                             ON TABLE public.storages TO "Суперпользователь";
ALTER TABLE public.storages OWNER TO "Суперпользователь";

-- ── suppliers ─────────────────────────────────────────────────────────────────
REVOKE ALL ON TABLE public.suppliers FROM "Менеджер";
REVOKE ALL ON TABLE public.suppliers FROM "Бухгалтер";
GRANT SELECT, INSERT, UPDATE, DELETE  ON TABLE public.suppliers TO "Менеджер";
GRANT SELECT                          ON TABLE public.suppliers TO "Бухгалтер";
GRANT ALL                             ON TABLE public.suppliers TO "Суперпользователь";
ALTER TABLE public.suppliers OWNER TO "Суперпользователь";

-- ── delivery_services ─────────────────────────────────────────────────────────
REVOKE ALL ON TABLE public.delivery_services FROM "Менеджер";
REVOKE ALL ON TABLE public.delivery_services FROM "Бухгалтер";
GRANT SELECT, INSERT, UPDATE, DELETE  ON TABLE public.delivery_services TO "Менеджер";
GRANT SELECT                          ON TABLE public.delivery_services TO "Бухгалтер";
GRANT ALL                             ON TABLE public.delivery_services TO "Суперпользователь";
ALTER TABLE public.delivery_services OWNER TO "Суперпользователь";

-- ── products ──────────────────────────────────────────────────────────────────
REVOKE ALL ON TABLE public.products FROM "Менеджер";
REVOKE ALL ON TABLE public.products FROM "Бухгалтер";
GRANT SELECT, INSERT, UPDATE, DELETE  ON TABLE public.products TO "Менеджер";
GRANT SELECT                          ON TABLE public.products TO "Бухгалтер";
GRANT ALL                             ON TABLE public.products TO "Суперпользователь";
ALTER TABLE public.products OWNER TO "Суперпользователь";

-- ── customers ─────────────────────────────────────────────────────────────────
REVOKE ALL ON TABLE public.customers FROM "Менеджер";
REVOKE ALL ON TABLE public.customers FROM "Бухгалтер";
GRANT SELECT, INSERT, UPDATE, DELETE  ON TABLE public.customers TO "Менеджер";
GRANT SELECT                          ON TABLE public.customers TO "Бухгалтер";
GRANT ALL                             ON TABLE public.customers TO "Суперпользователь";
ALTER TABLE public.customers OWNER TO "Суперпользователь";

-- ── orders ────────────────────────────────────────────────────────────────────
REVOKE ALL ON TABLE public.orders FROM "Менеджер";
REVOKE ALL ON TABLE public.orders FROM "Бухгалтер";
GRANT SELECT, INSERT, UPDATE, DELETE  ON TABLE public.orders TO "Менеджер";
GRANT SELECT                          ON TABLE public.orders TO "Бухгалтер";
GRANT ALL                             ON TABLE public.orders TO "Суперпользователь";
ALTER TABLE public.orders OWNER TO "Суперпользователь";

-- ── orders_products ───────────────────────────────────────────────────────────
REVOKE ALL ON TABLE public.orders_products FROM "Менеджер";
REVOKE ALL ON TABLE public.orders_products FROM "Бухгалтер";
GRANT SELECT, INSERT, UPDATE, DELETE  ON TABLE public.orders_products TO "Менеджер";
GRANT SELECT                          ON TABLE public.orders_products TO "Бухгалтер";
GRANT ALL                             ON TABLE public.orders_products TO "Суперпользователь";
ALTER TABLE public.orders_products OWNER TO "Суперпользователь";

-- ── deliveries ────────────────────────────────────────────────────────────────
REVOKE ALL ON TABLE public.deliveries FROM "Менеджер";
REVOKE ALL ON TABLE public.deliveries FROM "Бухгалтер";
GRANT SELECT, INSERT, UPDATE, DELETE  ON TABLE public.deliveries TO "Менеджер";
GRANT SELECT                          ON TABLE public.deliveries TO "Бухгалтер";
GRANT ALL                             ON TABLE public.deliveries TO "Суперпользователь";
ALTER TABLE public.deliveries OWNER TO "Суперпользователь";

-- ── returns ───────────────────────────────────────────────────────────────────
REVOKE ALL ON TABLE public.returns FROM "Менеджер";
REVOKE ALL ON TABLE public.returns FROM "Бухгалтер";
GRANT SELECT, INSERT, UPDATE, DELETE  ON TABLE public.returns TO "Менеджер";
GRANT SELECT                          ON TABLE public.returns TO "Бухгалтер";
GRANT ALL                             ON TABLE public.returns TO "Суперпользователь";
ALTER TABLE public.returns OWNER TO "Суперпользователь";


-- =====================================================
-- 5. ПРАВА НА ПОСЛЕДОВАТЕЛЬНОСТИ (SEQUENCES)
-- =====================================================
-- Необходимо для INSERT с автоинкрементом

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO "Менеджер";
-- Бухгалтер только читает, sequences не нужны
