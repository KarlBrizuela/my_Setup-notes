# Docker Setup for Existing Projects

A step-by-step guide for adding Docker to an existing development project using Docker Desktop on Windows.

## 1. Prerequisites

Make sure the following are installed:

- Docker Desktop
- Git
- VS Code

Verify Docker installation:

```powershell
docker --version
docker compose version
```

Make sure Docker Desktop is running before executing Docker commands.

---

## 2. Navigate to Your Project

Open PowerShell and navigate to your existing project directory.

```powershell
cd C:\Users\YourName\Projects\your-project
```

Example:

```powershell
cd C:\Users\karlb\Downloads\my-project
```

Check your project files:

```powershell
dir
```

---

## 3. Create Docker Configuration Files

Inside your project root directory, create the following files:

```text
your-project/
│
├── Dockerfile
├── compose.yaml
├── .dockerignore
│
├── src/
├── package.json
└── ...
```

The actual project structure depends on your framework.

---

## 4. Create Dockerfile

The Dockerfile defines how Docker builds your application image.

### Example: Next.js / Node.js

```dockerfile
FROM node:22-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "run", "dev"]
```

For this development configuration, make sure your Next.js development script is configured to listen on all interfaces:

```json
{
  "scripts": {
    "dev": "next dev -H 0.0.0.0"
  }
}
```

### Example: Laravel / PHP

Laravel requires PHP, Composer, a web server, and potentially additional services.

A basic PHP Dockerfile can be used as a starting point:

```dockerfile
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
```

Note: This is a development starting point, not a production Laravel deployment configuration. Install any additional PHP extensions required by your project.

---

## 5. Create compose.yaml

Docker Compose manages the containers and their configurations.

### Example: Next.js

```yaml
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
```

### Example: Laravel + MySQL

```yaml
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
```

For Laravel, configure your `.env` database connection:

```env
DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=laravel_db
DB_USERNAME=laravel
DB_PASSWORD=secret
```

Inside Docker, use the Compose service name (`db`) as the database hostname, not `localhost`.

---

## 6. Create .dockerignore

Prevent unnecessary files from being copied into the Docker image.

### Next.js

```text
node_modules
.next
.git
.env
.env.local
npm-debug.log
```

### Laravel

```text
.git
.env
vendor
node_modules
storage/logs/*
```

Adjust these exclusions depending on your deployment and build requirements.

---

## 7. Build and Run the Project

Open PowerShell inside the project directory.

### Build the Docker image

```powershell
docker compose build
```

### Start the containers

```powershell
docker compose up -d
```

### Build and start in one command

```powershell
docker compose up -d --build
```

### Check running containers

```powershell
docker compose ps
```

### View application logs

```powershell
docker compose logs -f app
```

### Open the application

Next.js:

```text
http://localhost:3000
```

Laravel:

```text
http://localhost:8000
```

---

## 8. Common Docker Commands

| Command | Purpose |
|---|---|
| `docker compose up -d` | Start containers in the background |
| `docker compose up -d --build` | Build and start containers |
| `docker compose down` | Stop and remove containers |
| `docker compose stop` | Stop containers |
| `docker compose start` | Start stopped containers |
| `docker compose restart` | Restart containers |
| `docker compose ps` | List project containers |
| `docker compose logs -f` | Follow container logs |
| `docker compose build` | Build images |
| `docker compose exec app sh` | Enter application container |
| `docker compose down -v` | Remove containers and named volumes |

**Warning:** `docker compose down -v` deletes the associated named volumes, which may contain your database data.

---

## 9. How to Apply Code Changes

When using Docker Compose with bind mounts:

1. Edit your project files in VS Code.
2. Save your changes.
3. Check the application in your browser.
4. The development server should detect changes automatically.

For Next.js, the bind mount allows the container to access your local source files.

You do not normally need to rebuild the image for ordinary source-code changes.

Rebuild when changing:

- Dockerfile
- Installed system dependencies
- Node.js or PHP base image
- Dependencies installed during image build

If your application does not detect changes:

```powershell
docker compose restart app
```

If dependencies or the image configuration changed:

```powershell
docker compose up -d --build
```

---

## 10. Working With Multiple Projects

Each project should have its own Dockerfile and Compose configuration.

Example:

```text
Projects/
│
├── portfolio/
│   ├── Dockerfile
│   └── compose.yaml
│
├── payroll/
│   ├── Dockerfile
│   └── compose.yaml
│
└── review-system/
    ├── Dockerfile
    └── compose.yaml
```

Each project can run independently.

Avoid assigning the same host port to multiple applications running simultaneously.

Example:

| Project | Local URL |
|---|---|
| Portfolio | localhost:3000 |
| Payroll | localhost:8000 |
| Review System | localhost:8080 |

---

## 11. Troubleshooting

### Port already allocated

If Docker reports that a port is already in use, change the host port in `compose.yaml`.

Example:

```yaml
ports:
  - "3001:3000"
```

Open:

```text
http://localhost:3001
```

### Container is not running

```powershell
docker compose ps -a
docker compose logs app
```

### Changes are not appearing

```powershell
docker compose restart app
```

Check that the project directory is mounted correctly.

### Rebuild the application

```powershell
docker compose down
docker compose up -d --build
```

### Remove unused containers and images

```powershell
docker system prune
```

Review the cleanup prompt before confirming.

---

## 12. Recommended Workflow

For every new project:

1. Create or open the project.
2. Navigate to the project root.
3. Create a Dockerfile.
4. Create a compose.yaml.
5. Create a .dockerignore.
6. Configure ports and environment variables.
7. Build the Docker image.
8. Start the containers.
9. Verify using `docker compose ps`.
10. Open the application in your browser.

**Daily development workflow:**

```powershell
# Start project
docker compose up -d

# Check containers
docker compose ps

# View logs
docker compose logs -f app

# Stop project
docker compose down
```

**Important:** Always create Docker configurations based on the project's actual framework, runtime version, dependencies, database, and development requirements. Do not blindly reuse the same Dockerfile across different projects.