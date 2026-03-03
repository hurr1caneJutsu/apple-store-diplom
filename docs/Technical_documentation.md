**Система функционирует на виртуальной машине в VMware Workstation.**

**OS - Ubuntu 24.04.4 LTS**

=======================================================================

**### Установка PostgreSQL 17.9 и pgAdmin4 9.12**

=======================================================================

**1. Обновление системы**

sudo apt update \&\& sudo apt upgrade -y

---

**2. Добавление официального репозитория PostgreSQL**

sudo apt install -y curl ca-certificates

sudo install -d /usr/share/postgresql-common/pgdg

sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc

. /etc/os-release

sudo sh -c "echo 'deb \[signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $VERSION\_CODENAME-pgdg main' > /etc/apt/sources.list.d/pgdg.list"

sudo apt update

---

**3. Установка PostgreSQL 17.9**

sudo apt install -y postgresql-17 postgresql-client-17

sudo systemctl status postgresql

sudo systemctl enable postgresql

sudo -u postgres psql

ALTER USER postgres WITH PASSWORD 'ПАРОЛЬ';

\\q

sudo nano /etc/postgresql/17/main/postgresql.conf

listen\_addresses = '\*'

sudo nano /etc/postgresql/17/main/pg\_hba.conf

host    all    all    192.168.0.0/24    scram-sha-256

sudo systemctl restart postgresql

psql -U postgres -h localhost

-------------------------------------------------------------------------------------------

**4. Установка pgAdmin4 9.12**

\# Скачиваем ключ

curl -fsS https://www.pgadmin.org/static/packages\_pgadmin\_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg

\# Добавляем репозиторий

sudo sh -c 'echo "deb \[signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb\_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list'

\# Обновляем список пакетов

sudo apt update

sudo apt install -y pgadmin4-desktop

---

=======================================================================

**### Установка Docker 29.2.1 и Docker Compose v5.1.0**

=======================================================================

**1. Обновление системы и установка зависимостей**

sudo apt update

sudo apt install -y ca-certificates curl gnupg lsb-release

---

**2. Удаление старых версий (если были)**

sudo apt remove -y docker docker-engine docker.io containerd runc

---

**3. Добавление официального GPG-ключа Docker**

sudo install -m 0755 -d /etc/apt/keyrings

sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

sudo chmod a+r /etc/apt/keyrings/docker.asc

---

**4. Добавление официального репозитория Docker**

sudo tee /etc/apt/sources.list.d/docker.sources <<EOF

**Вставляем:**

Types: deb

URIs: https://download.docker.com/linux/ubuntu

Suites: $(. /etc/os-release \&\& echo "${UBUNTU\_CODENAME:-$VERSION\_CODENAME}")

Components: stable

Signed-By: /etc/apt/keyrings/docker.asc

EOF

---

**5. Обновление списка пакетов с учётом нового репозитория**

sudo apt update

---

**6. Установка Docker Engine и плагинов**

sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

---

**7. Проверка, что Docker установлен и работает**

sudo systemctl status docker

sudo systemctl start docker

sudo systemctl enable docker

sudo docker run hello-world

---

8\. Настройка прав для обычного пользователя (чтобы не писать sudo)

sudo usermod -aG docker $USER

=======================================================================

**\### Создание контейнера NocoDB**

=======================================================================

**1. Создай папку для NocoDB**

mkdir ~/nocodb-appstore \&\& cd ~/nocodb-appstore

---

**2. Создаём файл docker-compose.yml**

nano docker-compose.yml

**Вставляем:**

services:

&nbsp; nocodb:

&nbsp;   image: nocodb/nocodb:latest

&nbsp;   container\_name: nocodb

&nbsp;   restart: unless-stopped

&nbsp;   network\_mode: "host"

&nbsp;   environment:

&nbsp;     NC\_DB: "pg://localhost:5432?u=postgres\&p=ПАРОЛЬ\&d=appstoreDB"

&nbsp;     NC\_AUTH\_JWT\_SECRET: "my-super-secret-jwt-key-2026"

---

**3. Запускаем NocoDB**

docker compose up -d

Проверяем, что контейнер запустился:

docker compose ps

Проверяем ошибки:

docker compose logs | tail -20

Открываем браузер, переходим по ссылке **http://localhost:8080**

---
