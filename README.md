
**🍎 APPLE STORE DATABASE SYSTEM**

Дипломный проект: База данных магазина электроники
---

Версия: 1.0
Дата: Март 2026
Автор: Maxim Belous

---
1. ОПИСАНИЕ ПРОЕКТА
---

Полноценная система управления базой данных для магазина электроники Apple.
Разработана на виртуальной машине VMware Workstation с Ubuntu 24.04.4 LTS.

КЛЮЧЕВЫЕ ВОЗМОЖНОСТИ:
----------------------
✅ PostgreSQL 17.9 с нормализованной структурой данных

✅ pgAdmin4 9.12 для администрирования

✅ Ролевая модель доступа (3 роли с разными правами)

✅ Docker + NocoDB для удобного веб-интерфейса

✅ Триггеры для автоматизации расчётов и контроля остатков

✅ Защита от брутфорса через auth_delay


---
2. ТЕХНОЛОГИЧЕСКИЙ СТЕК
---

VMware Workstation Pro 25H2
Ubuntu 24.04.4 LTS
PostgreSQL 17.9
PgAdmin4 9.12
Docker 29.2.1 и Docker Compose v5.1.0
Контейнер NocoDB

---
3. СТРУКТУРА БАЗЫ ДАННЫХ
---

СПРАВОЧНЫЕ ТАБЛИЦЫ:
- categories (категории товаров)
- colors (цвета)
- storages (объёмы памяти)
- suppliers (поставщики)
- delivery_services (службы доставки)

ОСНОВНЫЕ ТАБЛИЦЫ:
- products (товары)
- customers (клиенты)
- orders (заказы)
- orders_products (состав заказов)
- deliveries (доставки)
- returns (возвраты)

---
4. РОЛЕВАЯ МОДЕЛЬ
---

Суперпользователь - Полный доступ
Менеджер - Работа с заказами
Бухгалтер - Только чтение

Ограничения:
- Менеджер: не более 5 одновременных подключений
- Бухгалтер: не более 3 одновременных подключений
- Защита от брутфорса: задержка 3 секунды при неверном пароле

---
5. ТРИГГЕРЫ АВТОМАТИЗАЦИИ
---

1️⃣ update_order_total
   → Автоматический пересчёт суммы заказа

2️⃣ update_product_quantity
   → Контроль и обновление остатков на складе

3️⃣ check_return_quantity
   → Защита от возврата большего количества

4️⃣ check_delivery_type
   → Запрет доставки для самовывоза

5️⃣ check_order_status_for_return
   → Возврат только по завершённым заказам

6️⃣ check_refund_amount
   → Контроль суммы возврата

---
6. УСТАНОВКА И ЗАПУСК
---

ШАГ 1. Установка PostgreSQL и pgAdmin
--------------------------------------
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl ca-certificates

# Добавление репозитория PostgreSQL
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc

# Установка PostgreSQL 17.9
sudo apt install -y postgresql-17 postgresql-client-17

# Установка pgAdmin4
curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg
sudo apt update
sudo apt install -y pgadmin4-desktop


ШАГ 2. Создание структуры БД
-----------------------------
sudo -u postgres psql -f sql/apple_store_db_v3.sql
sudo -u postgres psql -f docs/Роли\ для\ БД.sql


ШАГ 3. Настройка конфигов
--------------------------
# Раскомментировать в postgresql.conf:
listen_addresses = '*'

# Добавить в pg_hba.conf:
host    all    all    192.168.0.0/24    scram-sha-256

sudo systemctl restart postgresql


ШАГ 4. Запуск NocoDB
---------------------
cd configs
docker compose up -d
# Открыть в браузере: http://localhost:8080

---
7. КОНФИГУРАЦИОННЫЕ ФАЙЛЫ
---

📁 configs/
├── postgresql.conf      # Основные настройки PostgreSQL
├── pg_hba.conf          # Настройки доступа клиентов
└── docker-compose.yml   # Конфигурация NocoDB

📁 sql/
└── apple_store_db_v3.sql  # Полная структура базы данных

📁 docs/
├── Техническая документация.md  # Подробная инструкция
└── Роли для БД.sql              # Скрипт создания ролей

---
8. ТЕСТОВЫЕ ДАННЫЕ
---

Для наполнения базы тестовыми данными используйте:

-- Добавление категорий
INSERT INTO categories (name) VALUES 
    ('iPhone'), ('iPad'), ('Mac'), ('AppleWatch'), ('AirPods'), ('Аксессуары');

-- Добавление цветов
INSERT INTO colors (name) VALUES 
    ('Black'), ('White'), ('Silver'), ('Space Gray'), 
    ('Midnight'), ('Starlight'), ('Gold'), ('Natural Titanium');

-- Добавление объёмов памяти
INSERT INTO storages (capacity) VALUES 
    ('128 ГБ'), ('256 ГБ'), ('512 ГБ'), ('1024 ГБ');

---
9. БЕЗОПАСНОСТЬ
---

✅ Защита от брутфорса через auth_delay (3 сек)
✅ Ограничение количества подключений
✅ Разграничение прав через GRANT/REVOKE
✅ Пароли хранятся в зашифрованном виде
✅ Внешние ключи с ON DELETE RESTRICT

---
10. РЕЗЕРВНОЕ КОПИРОВАНИЕ
---

Автоматический дамп через cron:
------------------------------
0 2 * * * pg_dump -U postgres appstoreDB > /backup/appstoreDB_$(date +\%Y\%m\%d).sql

Снимки VMware:
-------------
- Позволяют восстановить всю ВМ за минуты
- Хранятся на отдельном диске или в облаке

---
11. СИСТЕМНЫЕ ТРЕБОВАНИЯ
---

| Процессор             │ 2 ядра 
│ Оперативная память    │ 4 ГБ
│ Дисковое пространство │ 30 ГБ 
│ Виртуализация         │ VMware Workstation
│ Гостевая ОС           │ Ubuntu 24.04 LTS 

---
12. ПЛАНЫ ПО РАЗВИТИЮ
---

🔹 Внедрение репликации для отказоустойчивости
🔹 Настройка автоматических уведомлений в Telegram
🔹 Интеграция с 1С для обмена данными
🔹 Разработка мобильного приложения для менеджеров

---
13. КОНТАКТЫ
---

Автор: Belous Maxim
GitHub: https://github.com/твой-логин
Email: твой-email@example.com

---
---
© 2026 | Дипломный проект | Все права защищены
---
---
