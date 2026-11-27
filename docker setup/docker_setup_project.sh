#!/usr/bin/env bash

# ==============================================================================
# Docker Setup & Management Script for Existing Projects
# ==============================================================================
# Description: Automates Docker configuration generation (Dockerfile, compose.yaml,
#              .dockerignore) and provides handy daily management shortcuts.
# ==============================================================================

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
print_info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warn()    { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# ------------------------------------------------------------------------------
# 1. Prerequisite Checks
# ------------------------------------------------------------------------------
check_prerequisites() {
    print_info "Checking Docker prerequisites..."

    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH."
        print_info "Please install Docker Desktop and make sure it is running."
        exit 1
    fi

    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose (v2) is not available."
        exit 1
    fi

    if ! docker info &> /dev/null; then
        print_warn "Docker daemon is not running or cannot be reached."
        print_warn "Please start Docker Desktop and try again."
        exit 1
    fi

    print_success "Docker & Docker Compose are ready!"
    echo "  - Docker version: $(docker --version)"
    echo "  - Compose version: $(docker compose version --short 2>/dev/null || docker compose version)"
    echo ""
}

# ------------------------------------------------------------------------------
# 2. Scaffolding Generators
# ------------------------------------------------------------------------------
setup_nextjs() {
    print_info "Setting up Docker for Next.js / Node.js..."

    # Check for existing files
    if [ -f "Dockerfile" ] || [ -f "compose.yaml" ]; then
        read -rp "Dockerfile or compose.yaml already exists. Overwrite? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            print_warn "Setup cancelled."
            return
        fi
    fi

    # 1. Dockerfile
    cat << 'EOF' > Dockerfile
FROM node:22-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "run", "dev"]
EOF
    print_success "Created Dockerfile (Node.js 22 Alpine)"

    # 2. compose.yaml
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
    print_success "Created compose.yaml"

    # 3. .dockerignore
    cat << 'EOF' > .dockerignore
node_modules
.next
.git
.env
.env.local
npm-debug.log
EOF
    print_success "Created .dockerignore"

    echo ""
    print_info "Tips for Next.js:"
    echo "  - Make sure package.json dev script listens on 0.0.0.0:"
    echo '    "dev": "next dev -H 0.0.0.0"'
    echo "  - Run './docker_setup_project.sh up' to start containers."
    echo "  - Open in browser: http://localhost:3000"
    echo ""
}

setup_laravel() {
    print_info "Setting up Docker for Laravel / PHP + MySQL..."

    # Check for existing files
    if [ -f "Dockerfile" ] || [ -f "compose.yaml" ]; then
        read -rp "Dockerfile or compose.yaml already exists. Overwrite? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            print_warn "Setup cancelled."
            return
        fi
    fi

    # 1. Dockerfile
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
    print_success "Created Dockerfile (PHP 8.3 CLI + Composer)"

    # 2. compose.yaml
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
    print_success "Created compose.yaml"

    # 3. .dockerignore
    cat << 'EOF' > .dockerignore
.git
.env
vendor
node_modules
storage/logs/*
EOF
    print_success "Created .dockerignore"

    echo ""
    print_info "Tips for Laravel:"
    echo "  - Update your .env to connect to the database service:"
    echo "    DB_CONNECTION=mysql"
    echo "    DB_HOST=db"
    echo "    DB_PORT=3306"
    echo "    DB_DATABASE=laravel_db"
    echo "    DB_USERNAME=laravel"
    echo "    DB_PASSWORD=secret"
    echo "  - Run './docker_setup_project.sh up' to start containers."
    echo "  - Open in browser: http://localhost:8000"
    echo ""
}

# ------------------------------------------------------------------------------
# 3. Docker Management Shortcuts
# ------------------------------------------------------------------------------
docker_build() {
    print_info "Building Docker image(s)..."
    docker compose build
}

docker_up() {
    print_info "Starting containers in detached mode..."
    docker compose up -d
    docker compose ps
}

docker_rebuild() {
    print_info "Rebuilding and starting containers..."
    docker compose up -d --build
    docker compose ps
}

docker_stop() {
    print_info "Stopping containers..."
    docker compose stop
}

docker_down() {
    print_info "Stopping and removing containers..."
    docker compose down
}

docker_restart() {
    print_info "Restarting application container..."
    docker compose restart app
}

docker_status() {
    print_info "Checking container status..."
    docker compose ps
}

docker_logs() {
    print_info "Following container logs (Ctrl+C to exit)..."
    docker compose logs -f app
}

docker_shell() {
    print_info "Accessing application container shell..."
    docker compose exec app sh || docker compose exec app bash
}

docker_clean() {
    print_warn "This will remove unused Docker data (containers, networks, images)."
    read -rp "Are you sure? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        docker system prune
    else
        print_info "Clean cancelled."
    fi
}

# ------------------------------------------------------------------------------
# 4. Interactive Menu
# ------------------------------------------------------------------------------
show_menu() {
    echo -e "${BLUE}==============================================${NC}"
    echo -e "${GREEN}   Docker Setup & Management CLI Utility      ${NC}"
    echo -e "${BLUE}==============================================${NC}"
    echo " 1) Scaffold Next.js / Node.js Setup"
    echo " 2) Scaffold Laravel / PHP + MySQL Setup"
    echo " 3) Check Prerequisites & Docker Status"
    echo "----------------------------------------------"
    echo " 4) Start Containers (up -d)"
    echo " 5) Stop Containers (down)"
    echo " 6) Rebuild & Start (up -d --build)"
    echo " 7) View Container Status (ps)"
    echo " 8) View Application Logs (logs -f)"
    echo " 9) Restart App Container"
    echo "10) Open Shell in Container (exec sh)"
    echo "11) System Prune / Cleanup"
    echo " 0) Exit"
    echo -e "${BLUE}==============================================${NC}"
    read -rp "Select an option [0-11]: " choice

    case "$choice" in
        1) setup_nextjs ;;
        2) setup_laravel ;;
        3) check_prerequisites ;;
        4) docker_up ;;
        5) docker_down ;;
        6) docker_rebuild ;;
        7) docker_status ;;
        8) docker_logs ;;
        9) docker_restart ;;
        10) docker_shell ;;
        11) docker_clean ;;
        0) exit 0 ;;
        *) print_error "Invalid selection.";;
    esac
}

# ------------------------------------------------------------------------------
# Main Entry Point
# ------------------------------------------------------------------------------
case "$1" in
    check)      check_prerequisites ;;
    nextjs)     setup_nextjs ;;
    laravel)    setup_laravel ;;
    build)      docker_build ;;
    up)         docker_up ;;
    rebuild)    docker_rebuild ;;
    down)       docker_down ;;
    stop)       docker_stop ;;
    restart)    docker_restart ;;
    ps|status)  docker_status ;;
    logs)       docker_logs ;;
    shell)      docker_shell ;;
    clean)      docker_clean ;;
    help|--help|-h)
        echo "Usage: ./docker_setup_project.sh [command]"
        echo ""
        echo "Commands:"
        echo "  check       Verify Docker & Compose installation"
        echo "  nextjs      Generate Docker files for Next.js"
        echo "  laravel     Generate Docker files for Laravel + MySQL"
        echo "  up          Start containers in background"
        echo "  down        Stop and remove containers"
        echo "  rebuild     Rebuild images and restart containers"
        echo "  build       Build images without starting"
        echo "  stop        Stop containers without removing"
        echo "  restart     Restart application service"
        echo "  status|ps   Show running project containers"
        echo "  logs        Follow app logs"
        echo "  shell       Open shell inside app container"
        echo "  clean       Prune unused Docker resources"
        echo "  (no args)   Open interactive menu"
        ;;
    *)
        if [ -n "$1" ]; then
            print_error "Unknown command: $1"
            echo "Run './docker_setup_project.sh help' for usage."
            exit 1
        else
            show_menu
        fi
        ;;
esac
