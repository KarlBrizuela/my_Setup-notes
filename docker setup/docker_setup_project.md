# Docker Setup para sa Existing Projects

Praktikal na gabay sa paglalagay ng Docker sa existing project (Next.js, Node.js, Laravel, PHP, atbp.).

---

## Talaan ng Nilalaman
1. [Kahalagahan ng Docker sa Project](#1-kahalagahan-ng-docker-sa-project)
2. [Pangkalahatang Structure ng Files](#2-pangkalahatang-structure-ng-files)
3. [Setup Template: Next.js / Node.js](#3-setup-template-nextjs--nodejs)
4. [Setup Template: Laravel / PHP + MySQL](#4-setup-template-laravel--php--mysql)
5. [Araw-araw na Docker Commands (Cheat Sheet)](#5-araw-araw-na-docker-commands-cheat-sheet)
6. [Mga Karaniwang Problema at Solusyon (Troubleshooting)](#6-mga-karaniwang-problema-at-solusyon-troubleshooting)

---

## 1. Kahalagahan ng Docker sa Project

- **Parehong Environment sa Local at Production:** Binabalot ng Docker ang iyong code, dependencies, at tamang bersyon ng Node/PHP sa iisang container.
- **Hindi kailangang mag-install ng MySQL sa host machine:** Ang database ay tatakbo sa sarili nitong container nang hindi nagkakalat ng configuration files sa operating system mo.
- **Mabilisang Pagpapatakbo:** Isang command lang (`docker compose up -d`), bukas na ang buong application kasama ang database.

---

## 2. Pangkalahatang Structure ng Files

Sa loob ng root directory ng project, lumikha ng sumusunod na tatlong files:

```text
iyong-project/
├── Dockerfile          # Configuration kung paano bubuuin ang application image
├── compose.yaml        # Configuration ng services (app, database, ports, volumes)
├── .dockerignore       # Listahan ng files/folders na hindi dapat kopyahin sa image
├── src/ o app/
├── package.json / composer.json
└── ...
```

---

## 3. Setup Template: Next.js / Node.js

### A. Dockerfile (Next.js)

Lumikha ng file na `Dockerfile` sa root directory:

```dockerfile
# 1. Base image na may Node.js runtime
FROM node:22-alpine
# [PALIWANAG]: Magaan at mabilis na Linux (Alpine) na may Node.js v22.
# [PAPALITAN MO]: Kung Node 18 o 20 ang gamit mo, palitan ang '22'.

# 2. Working directory sa loob ng container
WORKDIR /app
# [PALIWANAG]: Dito ilalagay ang application files sa loob ng container.
# [WAG GALAWIN]: Standard path ito.

# 3. Kopyahin muna ang package manifests para sa caching
COPY package*.json ./
# [PALIWANAG]: Para sa Docker layer caching; hindi magre-run ng npm install kung walang binago sa package.json.
# [WAG GALAWIN]

# 4. I-install ang dependencies
RUN npm install
# [PALIWANAG]: Ini-install ang node_modules sa loob ng container.
# [PAPALITAN MO]: Kung pnpm gamit mo: RUN npm install -g pnpm && pnpm install

# 5. Kopyahin ang natitirang source code
COPY . .
# [PALIWANAG]: Kinokopya ang buong project folder papunta sa /app.
# [WAG GALAWIN]

# 6. Port ng application
EXPOSE 3000
# [PALIWANAG]: Port kung saan nakikinig ang Next.js application.
# [PAPALITAN MO]: Palitan kung may custom port ang Next.js setup mo.

# 7. Command para simulan ang development server
CMD ["npm", "run", "dev"]
# [PALIWANAG]: Awtomatikong pinapatakbo kapag binuksan ang container.
# [PAPALITAN MO]: Sa production Dockerfile, gamitin: CMD ["npm", "run", "start"]
```

> **Paalala para sa Next.js:**  
> Siguraduhing may `-H 0.0.0.0` ang iyong dev script sa `package.json` para ma-access ito mula sa browser ng host machine:
> ```json
> "scripts": {
>   "dev": "next dev -H 0.0.0.0"
> }
> ```

---

### B. compose.yaml (Next.js)

Lumikha ng `compose.yaml` sa root directory:

```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    # [PALIWANAG]: Bubuuin ang image gamit ang Dockerfile sa current directory.
    # [WAG GALAWIN]

    container_name: my-nextjs-app
    # [PAPALITAN MO]: Pangalan ng container para madaling matukoy sa 'docker ps'.

    ports:
      - "3000:3000"
    # [PALIWANAG]: Format ay "HOST_PORT:CONTAINER_PORT".
    # [PAPALITAN MO]: Ang kaliwang numero (3000) ay ang port sa iyong computer.
    #                 Kung may conflict sa port 3000, palitan ito ng "3001:3000"
    #                 (bubuksan sa browser: http://localhost:3001).

    volumes:
      - .:/app
    # [PALIWANAG]: BIND MOUNT: Kapag nag-save ka sa VS Code, kusa itong
    #              magre-reflect sa container nang hindi kailangang mag-rebuild.
    # [WAG GALAWIN]

      - /app/node_modules
      - /app/.next
    # [PALIWANAG]: Pinoprotektahan ang container-installed modules mula sa pagka-overwrite ng local folder.
    # [WAG GALAWIN]

    environment:
      - NODE_ENV=development
    # [WAG GALAWIN]

    restart: unless-stopped
    # [PALIWANAG]: Kusa itong magre-restart kung sakaling mag-crash ang container.
```

---

### C. .dockerignore (Next.js)

Lumikha ng `.dockerignore`:

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

### A. Dockerfile (Laravel)

```dockerfile
# 1. Base PHP Image
FROM php:8.3-cli
# [PALIWANAG]: PHP 8.3 CLI version.
# [PAPALITAN MO]: Kung PHP 8.2 ang kailangan ng project mo, palitan ang '8.3'.

# 2. Working directory
WORKDIR /var/www/html
# [PALIWANAG]: Default web directory path sa Linux.
# [WAG GALAWIN]

# 3. I-install ang system dependencies at PHP extensions
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    && docker-php-ext-install zip pdo_mysql
# [PALIWANAG]: Ini-install ang pdo_mysql extension para sa MySQL database connection.
# [PAPALITAN MO]: Magdagdag dito ng iba pang PHP extensions kung kailangan (hal. gd, bcmath, redis).

# 4. Kopyahin ang Composer mula sa official image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
# [PALIWANAG]: Nilalagay ang Composer binary para magamit ang 'composer install'.
# [WAG GALAWIN]

# 5. Kopyahin ang project source files
COPY . .
# [WAG GALAWIN]

# 6. I-install ang dependencies
RUN composer install
# [WAG GALAWIN]

# 7. Port definition
EXPOSE 8000
# [WAG GALAWIN]

# 8. Command para simulan ang development server
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
# [PALIWANAG]: Kailangan ang flag na '--host=0.0.0.0' para ma-access mula sa labas ng container.
# [WAG GALAWIN]
```

---

### B. compose.yaml (Laravel + MySQL)

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
    # [PAPALITAN MO]: Kung may conflict sa port 8000 sa host mo, palitan ang kaliwa (hal. "8080:8000").
    volumes:
      - .:/var/www/html
    # [PALIWANAG]: Bind mount para sa live sync ng code changes.
    depends_on:
      - db
    # [PALIWANAG]: Hihintayin munang magsimula ang database service bago ang app.

  # ==========================================
  # SERVICE 2: MYSQL DATABASE
  # ==========================================
  db:
    image: mysql:8.0
    container_name: laravel-db
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: laravel_db
      # [PAPALITAN MO]: Pangalan ng database.
      MYSQL_ROOT_PASSWORD: root
      # [PAPALITAN MO]: Password ng root admin.
      MYSQL_USER: laravel
      # [PAPALITAN MO]: Username para sa application.
      MYSQL_PASSWORD: secret
      # [PAPALITAN MO]: Password ng application user.
    ports:
      - "3307:3306"
    # [PALIWANAG]: Ginamit ang 3307 sa host para hindi bumangga kung may local MySQL sa port 3306.
    volumes:
      - mysql_data:/var/lib/mysql
    # [PALIWANAG]: Persistent storage; hindi mabubura ang data kahit tanggalin ang container.

volumes:
  mysql_data:
```

> **Paalala sa Laravel .env:**  
> I-update ang database configuration sa `.env` ng iyong Laravel project:
> ```env
> DB_CONNECTION=mysql
> DB_HOST=db             # 'db' ang ilalagay (service name sa compose), HINDI localhost
> DB_PORT=3306           # 3306 ang internal port sa loob ng Docker network
> DB_DATABASE=laravel_db
> DB_USERNAME=laravel
> DB_PASSWORD=secret
> ```

---

### C. .dockerignore (Laravel)

```text
.git
.env
vendor
node_modules
storage/logs/*
```

---

## 5. Araw-araw na Docker Commands (Cheat Sheet)

| Command | Kailan gagamitin |
|---|---|
| `docker compose up -d` | Simulan ang containers sa background (detached mode). |
| `docker compose down` | Ihinto at tanggalin ang containers. |
| `docker compose up -d --build` | I-rebuild at buksan ulit kapag may binago sa Dockerfile o dependencies. |
| `docker compose ps` | Tingnan ang status at port mappings ng mga container. |
| `docker compose logs -f app` | Tingnan ang live output at error logs ng application (`Ctrl + C` para lumabas). |
| `docker compose restart app` | I-restart ang application container nang hindi ginagalaw ang database. |
| `docker compose exec app sh` | Pumasok sa loob ng container terminal (hal. para sa database migrations). |
| `docker system prune -f` | Maglinis ng mga hindi na ginagamit na images at build cache. |

---

## 6. Mga Karaniwang Problema at Solusyon (Troubleshooting)

### Problema 1: "Port is already allocated" o Port Conflict
- **Dahilan:** May umiiral na proseso o serbisyo sa computer mo na gumagamit ng kaparehong port.
- **Solusyon:** Palitan ang **kaliwang numero** sa `ports` block sa loob ng `compose.yaml`:
  ```yaml
  ports:
    - "3005:3000"   # Ma-a-access sa http://localhost:3005
  ```

### Problema 2: Hindi lumalabas ang bagong dependencies (`npm install` o `composer require`)
- **Dahilan:** Ang mga packages ay na-cache sa image noong unang build.
- **Solusyon:** I-rebuild ang image gamit ang flag na `--build`:
  ```bash
  docker compose up -d --build
  ```

### Problema 3: "Cannot connect to database" sa Laravel
- **Dahilan:** Naka-set pa sa `localhost` o `127.0.0.1` ang `DB_HOST`.
- **Solusyon:** Palitan ang `DB_HOST` sa `.env`:
  ```env
  DB_HOST=db
  ```
