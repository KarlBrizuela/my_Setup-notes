# 🐳 Docker Setup para sa Existing Projects

Isang praktikal at madaling sundang gabay sa paglalagay ng Docker sa iyong existing project (Next.js, Node.js, Laravel, PHP, atbp.).

---

## 📌 Talaan ng Nilalaman
1. [Ano ang Silbi ng Docker sa Project Mo?](#1-ano-ang-silbi-ng-docker-sa-project-mo)
2. [Pangkalahatang Structure ng Files](#2-pangkalahatang-structure-ng-files)
3. [Setup Template: Next.js / Node.js](#3-setup-template-nextjs--nodejs)
4. [Setup Template: Laravel / PHP + MySQL](#4-setup-template-laravel--php--mysql)
5. [Araw-araw na Docker Commands (Cheat Sheet)](#5-araw-araw-na-docker-commands-cheat-sheet)
6. [Mga Karaniwang Problema at Solusyon (Troubleshooting)](#6-mga-karaniwang-problema-at-solusyon-troubleshooting)

---

## 1. Ano ang Silbi ng Docker sa Project Mo?

- **Walang "Gumagana sa PC ko pero sira sa server":** Binabalot ng Docker ang iyong code, dependencies, at tamang bersyon ng Node/PHP sa iisang container.
- **Hindi kailangang mag-install ng MySQL sa PC mo:** Ang database ay tatakbo sa loob ng sarili nitong container nang hindi nagkakalat ng files sa iyong operating system.
- **Madaling i-on at i-off:** Isang command lang (`docker compose up -d`), bukas na ang buong app at database.

---

## 2. Pangkalahatang Structure ng Files

Sa loob ng root folder ng iyong project, gagawa ka ng tatlong (3) bagong files:

```text
iyong-project/
├── Dockerfile          <-- Resipe kung paano bubuuin ang image ng app mo
├── compose.yaml        <-- Tagapamahala ng containers (app, database, ports)
├── .dockerignore       <-- Listahan ng mga folder na HINDI dapat isama sa container
├── src/ o app/
├── package.json / composer.json
└── ...
```

---

## 3. Setup Template: Next.js / Node.js

### 📄 A. `Dockerfile` (Next.js)

Gumawa ng file na pinangalanang `Dockerfile` sa root folder ng project mo:

```dockerfile
# 1. Base Operating System na may Node.js
FROM node:22-alpine
# 👉 [PARA SAAN]: Mabilis at magaan na Linux (Alpine) na may Node.js v22.
# ✏️ [PAPALITAN MO]: Kung Node 18 o 20 ang project mo, palitan ang '22'.

# 2. Folder sa loob ng container
WORKDIR /app
# 👉 [PARA SAAN]: Dito ilalagay ang lahat ng files sa loob ng container.
# 🔒 [WAG GALAWIN]: Standard ito.

# 3. Kopyahin muna ang package files para sa caching
COPY package*.json ./
# 👉 [PARA SAAN]: Para mabilis mag-build; hindi na magre-reinstall ng npm kung walang binago sa package.json.
# 🔒 [WAG GALAWIN]

# 4. I-install ang dependencies
RUN npm install
# 👉 [PARA SAAN]: Ini-install ang node_modules sa loob ng container.
# ✏️ [PAPALITAN MO]: Kung pnpm gamit mo: RUN npm install -g pnpm && pnpm install

# 5. Kopyahin ang natitirang source code
COPY . .
# 👉 [PARA SAAN]: Kinokopya ang buong project folder mo papunta sa /app.
# 🔒 [WAG GALAWIN]

# 6. Port ng application
EXPOSE 3000
# 👉 [PARA SAAN]: Nagpapahiwatig na sa port 3000 nakikinig ang Next.js.
# ✏️ [PAPALITAN MO]: Palitan kung may custom port ang iyong Next.js app.

# 7. Utos sa pagpapatakbo ng development server
CMD ["npm", "run", "dev"]
# 👉 [PARA SAAN]: Awtomatikong pinapatakbo kapag binuksan ang container.
# ✏️ [PAPALITAN MO]: Sa production, palitan ng: CMD ["npm", "run", "start"]
```

> ⚠️ **Mahalagang Paalala para sa Next.js:**  
> Buksan ang iyong `package.json` at siguraduhing may `-H 0.0.0.0` ang iyong dev script para ma-access ito mula sa labas ng container:
> ```json
> "scripts": {
>   "dev": "next dev -H 0.0.0.0"
> }
> ```

---

### 📄 B. `compose.yaml` (Next.js)

Gumawa ng file na `compose.yaml` sa root folder:

```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    # 👉 [PARA SAAN]: Bubuuin ang image gamit ang Dockerfile sa current directory.
    # 🔒 [WAG GALAWIN]

    container_name: my-nextjs-app
    # ✏️ [PAPALITAN MO]: Palitan ng kahit anong pangalan na gusto mo para sa container mo.

    ports:
      - "3000:3000"
    # 👉 [PARA SAAN]: Format ay "HOST_PORT:CONTAINER_PORT".
    # ✏️ [PAPALITAN MO]: Ang KALIWA (3000) ay ang port sa PC mo. 
    #                    Kung may gumagamit na ng 3000 sa PC mo, palitan ng "3001:3000"
    #                    (bubuksan sa browser: http://localhost:3001).

    volumes:
      - .:/app
    # 👉 [PARA SAAN]: BIND MOUNT! Tuwing magse-save ka ng code sa VS Code,
    #                 kusa itong magre-reflect sa container nang HINDI kailangang mag-rebuild.
    # 🔒 [WAG GALAWIN]

      - /app/node_modules
      - /app/.next
    # 👉 [PARA SAAN]: Iniiwasan na ma-overwrite ang container modules ng local folder mo.
    # 🔒 [WAG GALAWIN]

    environment:
      - NODE_ENV=development
    # 🔒 [WAG GALAWIN]

    restart: unless-stopped
    # 👉 [PARA SAAN]: Kusa itong magre-restart kung sakaling mag-crash.
```

---

### 📄 C. `.dockerignore` (Next.js)

Gumawa ng `.dockerignore` para hindi makopya ang mabibigat na pansamantalang files:

```text
node_modules
.next
.git
.env
.env.local
npm-debug.log
```

---

## 4. Setup Template: Laravel / PHP + MySQL

### 📄 A. `Dockerfile` (Laravel)

```dockerfile
# 1. Base PHP Image
FROM php:8.3-cli
# 👉 [PARA SAAN]: PHP 8.3 CLI version.
# ✏️ [PAPALITAN MO]: Kung PHP 8.2 ang project mo, palitan ang '8.3'.

# 2. Working directory
WORKDIR /var/www/html
# 👉 [PARA SAAN]: Default path para sa web projects sa Linux.
# 🔒 [WAG GALAWIN]

# 3. I-install ang Linux packages at PHP Extensions
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    && docker-php-ext-install zip pdo_mysql
# 👉 [PARA SAAN]: Ini-install ang pdo_mysql para makipag-usap ang Laravel sa MySQL database.
# ✏️ [PAPALITAN MO]: Magdagdag dito kung kailangan ng 'gd', 'bcmath', o 'redis'.

# 4. Kunin ang Composer mula sa opisyal na image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
# 👉 [PARA SAAN]: Nilalagay ang Composer 2 sa container para magamit ang 'composer install'.
# 🔒 [WAG GALAWIN]

# 5. Kopyahin ang project files
COPY . .
# 🔒 [WAG GALAWIN]

# 6. I-install ang PHP dependencies
RUN composer install
# 🔒 [WAG GALAWIN]

# 7. Buksan ang port
EXPOSE 8000
# 🔒 [WAG GALAWIN]

# 8. Patakbuhin ang built-in server
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
# 👉 [PARA SAAN]: Kailangan ang '--host=0.0.0.0' para ma-access sa browser ng computer mo.
# 🔒 [WAG GALAWIN]
```

---

### 📄 B. `compose.yaml` (Laravel + MySQL)

```yaml
services:
  # ==========================================
  # SERVICE 1: LARAVEL APPLICATION
  # ==========================================
  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: laravel-app
    ports:
      - "8000:8000"
    # ✏️ [PAPALITAN MO]: Kung may conflict sa 8000, palitan ang kaliwa (hal. "8080:8000").
    volumes:
      - .:/var/www/html
    # 👉 [PARA SAAN]: Bind mount para sa live reload ng code mo.
    depends_on:
      - db
    # 👉 [PARA SAAN]: Hihintaying magsimula muna ang database bago buksan ang Laravel.

  # ==========================================
  # SERVICE 2: MYSQL DATABASE
  # ==========================================
  db:
    image: mysql:8.0
    container_name: laravel-db
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: laravel_db
      # ✏️ [PAPALITAN MO]: Pangalan ng database mo.
      MYSQL_ROOT_PASSWORD: root
      # ✏️ [PAPALITAN MO]: Password ng root admin.
      MYSQL_USER: laravel
      # ✏️ [PAPALITAN MO]: Username ng app.
      MYSQL_PASSWORD: secret
      # ✏️ [PAPALITAN MO]: Password ng user.
    ports:
      - "3307:3306"
    # 👉 [PARA SAAN]: Ginamit ang 3307 sa PC mo para hindi bumangga kung may local MySQL ka na sa port 3306!
    volumes:
      - mysql_data:/var/lib/mysql
    # 👉 [PARA SAAN]: Dito nakatago ang data para HINDI mabura kahit patayin ang Docker.

volumes:
  mysql_data:
```

> 💡 **Paano i-connect ang Laravel `.env` sa Docker Database:**  
> Buksan ang `.env` ng iyong Laravel project at i-set ang sumusunod:
> ```env
> DB_CONNECTION=mysql
> DB_HOST=db             <-- 'db' ang ilalagay (service name sa compose), HINDI localhost!
> DB_PORT=3306           <-- 3306 ang internal port sa loob ng Docker network
> DB_DATABASE=laravel_db
> DB_USERNAME=laravel
> DB_PASSWORD=secret
> ```

---

### 📄 C. `.dockerignore` (Laravel)

```text
.git
.env
vendor
node_modules
storage/logs/*
```

---

## 5. Araw-araw na Docker Commands (Cheat Sheet)

Kopyahin ang mga commands na ito sa terminal sa loob ng project folder mo:

| Command | Para saan ito? (Kailan gagamitin) |
|---|---|
| `docker compose up -d` | **Simulan ang app** sa background (detached mode). |
| `docker compose down` | **Ihinto at tanggalin** ang containers kapag tapos ka na magtrabaho. |
| `docker compose up -d --build` | **I-rebuild at buksan** kapag may binago ka sa `Dockerfile` o nagdagdag ng bagong package. |
| `docker compose ps` | **Tingnan ang status** (kung tumatakbo ba ang containers at anong ports). |
| `docker compose logs -f app` | **Tingnan ang live error logs** ng application mo (`Ctrl + C` para lumabas). |
| `docker compose restart app` | **I-restart** lang ang application container nang hindi pinapatay ang database. |
| `docker compose exec app sh` | **Pumasok sa loob ng container terminal** (hal. para mag-run ng `php artisan migrate`). |
| `docker system prune -f` | **Maglinis** ng mga lumang cache at hindi ginagamit na Docker images para makatipid sa hard drive. |

---

## 6. Mga Karaniwang Problema at Solusyon (Troubleshooting)

### ❓ Problema 1: "Port is already allocated" o Port Conflict
- **Dahilan:** May isa pang app o serbisyo sa computer mo na gumagamit ng parehong port (hal. 3000 o 8000).
- **Solusyon:** Buksan ang `compose.yaml` at palitan ang **kaliwang port number**:
  ```yaml
  ports:
    - "3005:3000"   # Ma-a-access mo na ito sa http://localhost:3005
  ```

### ❓ Problema 2: Hindi nagre-reflect ang bagong packages (`npm install` o `composer require`)
- **Dahilan:** Ang mga packages ay binuo sa loob ng image noong unang build.
- **Solusyon:** Patakbuhin ang command na may `--build`:
  ```bash
  docker compose up -d --build
  ```

### ❓ Problema 3: "Cannot connect to database" sa Laravel
- **Dahilan:** Naka-set pa sa `DB_HOST=127.0.0.1` o `localhost` ang iyong `.env`.
- **Solusyon:** Palitan ito ng:
  ```env
  DB_HOST=db
  ```
  *(Dahil sa Docker Compose, ang pangalan ng service sa `compose.yaml` ang nagsisilbing hostname nito).*
