#!/usr/bin/env bash

# ==============================================================================
# 🐳 DOCKER SETUP PARA SA MGA EXISTING PROJECTS (Next.js, Laravel, atbp.)
# ==============================================================================
# Ano ang silbi ng Docker sa project mo?
#  - Binabalot ng Docker ang buong application mo (code, runtime, dependencies)
#    sa loob ng isang container.
#  - "Gumagana sa computer ko, pero hindi sa server?" -> Wala nang ganoong problema!
#    Dahil parehas ang kapaligiran (environment) sa local man o sa live server.
# ==============================================================================

set -e

# Mga Kulay para maganda at madaling basahin sa terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_title()   { echo -e "\n${BOLD}${BLUE}=== $1 ===${NC}\n"; }
print_info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warn()    { echo -e "${YELLOW}[PAALALA]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# ------------------------------------------------------------------------------
# 1. PALIWANAG KADA LINYA: NEXT.JS / NODE.JS SETUP
# ------------------------------------------------------------------------------
explain_nextjs() {
    print_title "PALIWANAG KADA LINYA: NEXT.JS / NODE.JS SETUP"
    cat << 'EOF'
--------------------------------------------------------------------------------
📄 A. DOCKERFILE PARA SA NEXT.JS:
--------------------------------------------------------------------------------
FROM node:22-alpine
# 👉 [PALIWANAG]: Ang base image natin ay lightweight Linux na may Node.js version 22.
# ✏️ [PAPALITAN MO]: Kung Node 18 o 20 ang gamit mo, palitan ang '22'. Ang 'alpine' ay maliit at mabilis.

WORKDIR /app
# 👉 [PALIWANAG]: Gumagawa ng folder na '/app' sa loob ng container at doon ilalagay ang files.
# 🔒 [WAG GALAWIN]: Standard ito, hindi kailangang baguhin.

COPY package*.json ./
# 👉 [PALIWANAG]: Kinokopya muna ang package.json at package-lock.json bago ang buong code.
# 🔒 [WAG GALAWIN]: Para sa Docker caching — para mabilis mag-build at hindi paulit-ulit mag-npm install.

RUN npm install
# 👉 [PALIWANAG]: Ini-install ang lahat ng node_modules sa loob ng container.
# ✏️ [PAPALITAN MO]: Kung pnpm gamit mo: 'RUN npm install -g pnpm && pnpm install'.

COPY . .
# 👉 [PALIWANAG]: Kinokopya na ang natitirang source code mo papunta sa /app sa container.
# 🔒 [WAG GALAWIN]

EXPOSE 3000
# 👉 [PALIWANAG]: Sinasabi sa Docker na sa port 3000 nakikinig ang application.
# ✏️ [PAPALITAN MO]: Kung ibang port ang gamit ng Next.js mo, palitan ang 3000.

CMD ["npm", "run", "dev"]
# 👉 [PALIWANAG]: Ang utos na patatakbuhin pagkabukas ng container para simulan ang development server.
# ✏️ [PAPALITAN MO]: Sa production: 'CMD ["npm", "run", "start"]'.

--------------------------------------------------------------------------------
📄 B. COMPOSE.YAML PARA SA NEXT.JS:
--------------------------------------------------------------------------------
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
# 👉 [PALIWANAG]: Sinasabi kung saang Dockerfile bubuuin ang image (dito sa current directory).
# 🔒 [WAG GALAWIN]

    container_name: my-project-app
# ✏️ [PAPALITAN MO]: Palitan ng kahit anong gusto mong pangalan ng container mo (hal. portfolio-app).

    ports:
      - "3000:3000"
# 👉 [PALIWANAG]: Format: "HOST_PORT:CONTAINER_PORT".
# ✏️ [PAPALITAN MO]: Kung may iba nang gumagamit ng port 3000 sa computer mo,
#                    baguhin ang KALIWA: "3001:3000" (bubuksan sa browser: localhost:3001).

    volumes:
      - .:/app
# 👉 [PALIWANAG]: BIND MOUNT! Tuwing magse-save ka ng code sa VS Code sa PC mo,
#                 kusa itong makikita sa loob ng container nang hindi kailangang mag-rebuild!
# 🔒 [WAG GALAWIN]

      - /app/node_modules
      - /app/.next
# 👉 [PALIWANAG]: Iniiwasan na ma-overwrite ang container node_modules ng local node_modules mo.
# 🔒 [WAG GALAWIN]

    environment:
      - NODE_ENV=development
# 🔒 [WAG GALAWIN]

    restart: unless-stopped
# 👉 [PALIWANAG]: Kapag nag-crash o nag-restart ang Docker, kusa itong bubuhayin ulit.
--------------------------------------------------------------------------------
EOF
}

# ------------------------------------------------------------------------------
# 2. PALIWANAG KADA LINYA: LARAVEL / PHP + MYSQL SETUP
# ------------------------------------------------------------------------------
explain_laravel() {
    print_title "PALIWANAG KADA LINYA: LARAVEL / PHP + MYSQL SETUP"
    cat << 'EOF'
--------------------------------------------------------------------------------
📄 A. DOCKERFILE PARA SA LARAVEL:
--------------------------------------------------------------------------------
FROM php:8.3-cli
# 👉 [PALIWANAG]: Gumagamit ng PHP 8.3 command-line interface.
# ✏️ [PAPALITAN MO]: Kung PHP 8.2 ang kailangan ng project mo, palitan ang 8.3.

WORKDIR /var/www/html
# 👉 [PALIWANAG]: Ang default folder sa Linux kung saan inilalagay ang web apps.
# 🔒 [WAG GALAWIN]

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    && docker-php-ext-install zip pdo_mysql
# 👉 [PALIWANAG]: Nag-i-install ng Linux packages at PHP extensions (lalo na ang pdo_mysql para sa database).
# ✏️ [PAPALITAN MO]: Kung kailangan mo ng gd (image processing) o redis, idagdag dito.

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
# 👉 [PALIWANAG]: Kinukuha ang official Composer 2 binary para magamit sa container.
# 🔒 [WAG GALAWIN]

COPY . .
# 👉 [PALIWANAG]: Kinokopya ang buong Laravel source code mo sa container.
# 🔒 [WAG GALAWIN]

RUN composer install
# 👉 [PALIWANAG]: Ini-install ang mga PHP vendor packages.
# 🔒 [WAG GALAWIN]

EXPOSE 8000
# 👉 [PALIWANAG]: Ang port ng Laravel artisan serve.
# 🔒 [WAG GALAWIN]

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
# 👉 [PALIWANAG]: Pinapatakbo ang Laravel built-in development server.
# 🔒 [WAG GALAWIN]: Ang '--host=0.0.0.0' ay kailangan para ma-access mula sa labas ng container!

--------------------------------------------------------------------------------
📄 B. COMPOSE.YAML PARA SA LARAVEL + MYSQL:
--------------------------------------------------------------------------------
services:
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
# 👉 [PALIWANAG]: Bind mount para makita agad ang bago mong code nang walang rebuild.
    depends_on:
      - db
# 👉 [PALIWANAG]: Sinasabi na unahing buksan ang database bago ang Laravel app.

  db:
    image: mysql:8.0
# 👉 [PALIWANAG]: MySQL version 8.0 official image mula sa Docker Hub.
    container_name: laravel-db
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: laravel_db
# ✏️ [PAPALITAN MO]: Pangalan ng database na gusto mo.
      MYSQL_ROOT_PASSWORD: root
# ✏️ [PAPALITAN MO]: Root password ng MySQL.
      MYSQL_USER: laravel
# ✏️ [PAPALITAN MO]: Username ng regular user.
      MYSQL_PASSWORD: secret
# ✏️ [PAPALITAN MO]: Password ng regular user.
    ports:
      - "3307:3306"
# 👉 [PALIWANAG]: Ginamit ang 3307 sa computer mo para hindi bumangga kung may naka-install 
#                 ka nang local MySQL sa port 3306!
    volumes:
      - mysql_data:/var/lib/mysql
# 👉 [PALIWANAG]: Dito ise-save ang data ng database para kahit i-down ang container, HINDI mabubura ang data mo!

volumes:
  mysql_data:
--------------------------------------------------------------------------------
💡 PAALALA SA LARAVEL .ENV:
   Sa loob ng iyong .env file, palitan ang database settings ng ganito:
     DB_CONNECTION=mysql
     DB_HOST=db             <-- 'db' ang ilalagay (pangalan ng service), HINDI localhost!
     DB_PORT=3306
     DB_DATABASE=laravel_db
     DB_USERNAME=laravel
     DB_PASSWORD=secret
--------------------------------------------------------------------------------
EOF
}

# ------------------------------------------------------------------------------
# 3. PREREQUISITES CHECK
# ------------------------------------------------------------------------------
check_prerequisites() {
    print_title "PAGSUSURI SA DOCKER AT DOCKER COMPOSE"

    if ! command -v docker &> /dev/null; then
        print_error "Hindi naka-install ang Docker o wala sa iyong PATH."
        print_info "I-install ang Docker Desktop at siguraduhing bukas ito."
        exit 1
    fi

    if ! docker compose version &> /dev/null; then
        print_error "Hindi ma-access ang Docker Compose."
        exit 1
    fi

    if ! docker info &> /dev/null; then
        print_warn "Bukas ba ang Docker Desktop? Hindi ma-contact ang Docker daemon."
        print_info "Paki-buksan ang Docker Desktop app bago magpatuloy."
        exit 1
    fi

    print_success "Handa na ang Docker at Docker Compose!"
    echo "  - Docker: $(docker --version)"
    echo "  - Compose: $(docker compose version --short 2>/dev/null || docker compose version)"
    echo ""
}

# ------------------------------------------------------------------------------
# 4. SCAFFOLDING GENERATORS
# ------------------------------------------------------------------------------
setup_nextjs() {
    print_title "PAGGAWA NG MGA FILES PARA SA NEXT.JS / NODE.JS"

    if [ -f "Dockerfile" ] || [ -f "compose.yaml" ]; then
        read -rp "May Dockerfile o compose.yaml na. Papalitan ba? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            print_warn "Kinansela ang paggawa ng files."
            return
        fi
    fi

    # Dockerfile
    cat << 'EOF' > Dockerfile
FROM node:22-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "run", "dev"]
EOF
    print_success "Nagawa na ang: Dockerfile (Node.js 22 Alpine)"

    # compose.yaml
    cat << 'EOF' > compose.yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: my-project-app
    ports:
      - "3000:3000"
    volumes:
      - .:/app
      - /app/node_modules
      - /app/.next
    environment:
      - NODE_ENV=development
    restart: unless-stopped
EOF
    print_success "Nagawa na ang: compose.yaml"

    # .dockerignore
    cat << 'EOF' > .dockerignore
node_modules
.next
.git
.env
.env.local
npm-debug.log
EOF
    print_success "Nagawa na ang: .dockerignore"

    echo ""
    print_info "PAALALA PARA SA NEXT.JS:"
    echo "  Siguraduhing sa package.json ay may -H 0.0.0.0:"
    echo '    "dev": "next dev -H 0.0.0.0"'
    echo "  Patakbuhin: './docker_setup_project.sh up'"
    echo "  Buksan sa browser: http://localhost:3000"
    echo ""
}

setup_laravel() {
    print_title "PAGGAWA NG MGA FILES PARA SA LARAVEL / PHP + MYSQL"

    if [ -f "Dockerfile" ] || [ -f "compose.yaml" ]; then
        read -rp "May Dockerfile o compose.yaml na. Papalitan ba? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            print_warn "Kinansela ang paggawa ng files."
            return
        fi
    fi

    # Dockerfile
    cat << 'EOF' > Dockerfile
FROM php:8.3-cli

WORKDIR /var/www/html

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    && docker-php-ext-install zip pdo_mysql

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY . .

RUN composer install

EXPOSE 8000

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
EOF
    print_success "Nagawa na ang: Dockerfile (PHP 8.3 CLI + Composer)"

    # compose.yaml
    cat << 'EOF' > compose.yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: laravel-app
    ports:
      - "8000:8000"
    volumes:
      - .:/var/www/html
    depends_on:
      - db

  db:
    image: mysql:8.0
    container_name: laravel-db
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: laravel_db
      MYSQL_ROOT_PASSWORD: root
      MYSQL_USER: laravel
      MYSQL_PASSWORD: secret
    ports:
      - "3307:3306"
    volumes:
      - mysql_data:/var/lib/mysql

volumes:
  mysql_data:
EOF
    print_success "Nagawa na ang: compose.yaml"

    # .dockerignore
    cat << 'EOF' > .dockerignore
.git
.env
vendor
node_modules
storage/logs/*
EOF
    print_success "Nagawa na ang: .dockerignore"

    echo ""
    print_info "PAALALA SA DATABASE CONNECTION SA .ENV:"
    echo "  DB_CONNECTION=mysql"
    echo "  DB_HOST=db"
    echo "  DB_PORT=3306"
    echo "  DB_DATABASE=laravel_db"
    echo "  DB_USERNAME=laravel"
    echo "  DB_PASSWORD=secret"
    echo "  Patakbuhin: './docker_setup_project.sh up'"
    echo "  Buksan sa browser: http://localhost:8000"
    echo ""
}

# ------------------------------------------------------------------------------
# 5. DOCKER MANAGEMENT COMMANDS
# ------------------------------------------------------------------------------
docker_build()   { print_info "Binubuo ang Docker image(s)..."; docker compose build; }
docker_up()      { print_info "Binubuksan ang containers sa background..."; docker compose up -d; docker compose ps; }
docker_rebuild() { print_info "Nire-rebuild at binubuksan ulit ang containers..."; docker compose up -d --build; docker compose ps; }
docker_down()    { print_info "Hinihinto at tinatanggal ang containers..."; docker compose down; }
docker_restart() { print_info "Nire-restart ang application container..."; docker compose restart app; }
docker_status()  { print_info "Tinitingnan ang status ng mga container..."; docker compose ps; }
docker_logs()    { print_info "Tinitingnan ang logs ng app (Pindutin ang Ctrl+C para lumabas)..."; docker compose logs -f app; }
docker_shell()   { print_info "Pumapasok sa shell ng app container..."; docker compose exec app sh || docker compose exec app bash; }
docker_clean() {
    print_warn "Tatanggalin ang mga hindi ginagamit na containers, images, at networks."
    read -rp "Sigurado ka ba? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        docker system prune -f
        print_success "Nalinis na ang system!"
    fi
}

# ------------------------------------------------------------------------------
# 6. INTERACTIVE MENU
# ------------------------------------------------------------------------------
show_menu() {
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${GREEN}    DOCKER PROJECT SETUP & MANAGEMENT UTILITY        ${NC}"
    echo -e "${BLUE}======================================================${NC}"
    echo " 1) Paliwanag Kada Linya: Next.js / Node.js Setup"
    echo " 2) Paliwanag Kada Linya: Laravel / PHP + MySQL Setup"
    echo " 3) I-check ang Docker Prerequisites"
    echo "------------------------------------------------------"
    echo " 4) I-scaffold ang Next.js Setup (Dockerfile, compose, .dockerignore)"
    echo " 5) I-scaffold ang Laravel Setup (Dockerfile, compose, .dockerignore)"
    echo "------------------------------------------------------"
    echo " 6) Patakbuhin ang Containers (docker compose up -d)"
    echo " 7) Ihinto ang Containers (docker compose down)"
    echo " 8) Rebuild & Restart (docker compose up -d --build)"
    echo " 9) Tingnan ang Status (docker compose ps)"
    echo "10) Tingnan ang Live Logs (docker compose logs -f)"
    echo "11) Pumasok sa loob ng Container (shell)"
    echo "12) Maglinis ng lumang Docker cache (prune)"
    echo " 0) Exit"
    echo -e "${BLUE}======================================================${NC}"
    read -rp "Pumili ng numero [0-12]: " choice

    case "$choice" in
        1) explain_nextjs ;;
        2) explain_laravel ;;
        3) check_prerequisites ;;
        4) setup_nextjs ;;
        5) setup_laravel ;;
        6) docker_up ;;
        7) docker_down ;;
        8) docker_rebuild ;;
        9) docker_status ;;
        10) docker_logs ;;
        11) docker_shell ;;
        12) docker_clean ;;
        0) exit 0 ;;
        *) print_error "Maling numero. Pumili mula 0 hanggang 12.";;
    esac
}

# ------------------------------------------------------------------------------
# ENTRY POINT
# ------------------------------------------------------------------------------
case "$1" in
    explain-next)   explain_nextjs ;;
    explain-php)    explain_laravel ;;
    check)          check_prerequisites ;;
    nextjs)         setup_nextjs ;;
    laravel)        setup_laravel ;;
    build)          docker_build ;;
    up)             docker_up ;;
    rebuild)        docker_rebuild ;;
    down)           docker_down ;;
    restart)        docker_restart ;;
    ps|status)      docker_status ;;
    logs)           docker_logs ;;
    shell)          docker_shell ;;
    clean)          docker_clean ;;
    help|--help|-h)
        echo "Gamit: ./docker_setup_project.sh [command]"
        echo ""
        echo "Mga Command:"
        echo "  explain-next Tingnan ang paliwanag kada linya para sa Next.js"
        echo "  explain-php  Tingnan ang paliwanag kada linya para sa Laravel"
        echo "  check        Suriin ang Docker installation"
        echo "  nextjs       Kusang gumawa ng Next.js Docker files"
        echo "  laravel      Kusang gumawa ng Laravel Docker files"
        echo "  up           Simulan ang containers sa background"
        echo "  down         Ihinto ang containers"
        echo "  rebuild      I-rebuild at i-restart ang containers"
        echo "  logs         Tingnan ang logs ng app"
        echo "  shell        Pumasok sa loob ng app container"
        echo "  (walang arg) Bubuksan ang interactive Tagalog menu"
        ;;
    *)
        if [ -n "$1" ]; then
            print_error "Hindi kilalang utos: $1"
            echo "Patakbuhin ang './docker_setup_project.sh help' para sa gabay."
            exit 1
        else
            show_menu
        fi
        ;;
esac
