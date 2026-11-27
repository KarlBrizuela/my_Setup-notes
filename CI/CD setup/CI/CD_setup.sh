# CI/CD Setup Using GitHub Actions and Docker

A practical guide for automating application testing, Docker image building, and deployment using GitHub Actions.

## 1. Prerequisites

Make sure you have:

- GitHub account
- Git installed
- Docker Desktop installed
- Existing project repository on GitHub
- Dockerfile configured for production
- A VPS or cloud server for automatic deployment (for CD)

## 2. Project Structure

Inside your project root, create the following structure:

```text
your-project/
│
├── .github/
│   └── workflows/
│       └── deploy.yml
│
├── Dockerfile
├── compose.yaml
├── .dockerignore
├── package.json
└── ...
```

The `.github/workflows/` directory contains your GitHub Actions workflow files.

## 3. Create GitHub Actions Workflow

Create:

```text
.github/workflows/deploy.yml
```

Example workflow for a Dockerized Next.js application:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches:
      - main

  pull_request:
    branches:
      - main

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:

  # =========================
  # CI: TEST APPLICATION
  # =========================

  test:
    name: Run Tests
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm

      - name: Install Dependencies
        run: npm ci

      - name: Run Tests
        run: npm test --if-present

      - name: Build Application
        run: npm run build

  # =========================
  # CI: BUILD DOCKER IMAGE
  # =========================

  docker:
    name: Build and Push Docker Image
    runs-on: ubuntu-latest
    needs: test

    if: github.event_name == 'push' && github.ref == 'refs/heads/main'

    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Setup Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract Metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            type=raw,value=latest
            type=sha

      - name: Build and Push Image
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}

  # =========================
  # CD: DEPLOY TO SERVER
  # =========================

  deploy:
    name: Deploy Application
    runs-on: ubuntu-latest
    needs: docker

    steps:
      - name: Deploy Through SSH
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SERVER_SSH_KEY }}
          port: ${{ secrets.SERVER_PORT }}
          script: |
            cd ${{ secrets.APP_PATH }}

            echo "${{ secrets.GHCR_READ_TOKEN }}" | docker login ghcr.io -u "${{ secrets.GHCR_USERNAME }}" --password-stdin

            docker compose pull
            docker compose up -d --remove-orphans

            docker image prune -f
```

**Important:** This example assumes a production-ready Next.js Dockerfile and a VPS that already has Docker and Docker Compose installed. The workflow uses Node.js 22 as an example; match it to your project's actual runtime.

## 4. Configure GitHub Secrets

Your workflow needs credentials to connect to your production server.

Go to your GitHub repository:

```text
Settings
   |
   Secrets and variables
   |
   Actions
   |
   New repository secret
```

Add these secrets:

| Secret Name | Description |
|---|---|
| `SERVER_HOST` | Your VPS IP address or hostname |
| `SERVER_USER` | SSH username |
| `SERVER_SSH_KEY` | Private SSH key |
| `SERVER_PORT` | SSH port, usually 22 |
| `APP_PATH` | Project directory on your VPS |
| `GHCR_USERNAME` | GitHub username |
| `GHCR_READ_TOKEN` | GitHub Personal Access Token with read:packages permission |

Never commit private SSH keys, passwords, or access tokens to your repository.

For the GitHub Container Registry, make sure your deployment server is authorized to pull the package.

## 5. Configure Production Docker Compose

On your VPS, create a `compose.yaml` file.

Example:

```yaml
services:
  app:
    image: ghcr.io/your-github-username/your-repository:latest
    container_name: production-app
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: production
```

Replace the image name with your actual GitHub Container Registry image.

Make sure the server has this file in the directory specified by `APP_PATH`.

## 6. Prepare Your Production Server

Install Docker and Docker Compose on your VPS.

Verify:

```bash
docker --version
docker compose version
```

Create your application directory:

```bash
mkdir -p ~/apps/your-project
cd ~/apps/your-project
```

Place your production `compose.yaml` inside this directory.

Make sure your server can authenticate with GitHub Container Registry.

## 7. Push Your Project to GitHub

From your local project directory:

```bash
git add .

git commit -m "Add CI/CD pipeline"

git push origin main
```

After pushing, GitHub Actions will automatically execute your workflow.

## 8. Monitor Your CI/CD Pipeline

Go to your GitHub repository.

```text
Repository
   |
Actions
   |
CI/CD Pipeline
```

You should see the following jobs:

1. Run Tests
2. Build and Push Docker Image
3. Deploy Application

A successful workflow means all required jobs completed.

## 9. How the CI/CD Process Works

```text
Developer
    |
    | git push origin main
    v
GitHub Repository
    |
    v
GitHub Actions
    |
    v
Run Tests
    |
    v
Build Application
    |
    v
Build Docker Image
    |
    v
Push Image to GHCR
    |
    v
Connect to VPS through SSH
    |
    v
Pull Latest Docker Image
    |
    v
Restart Application
    |
    v
Production Application Updated
```

## 10. Common Git Commands

```bash
# Check current branch
git branch

# Check changes
git status

# Stage changes
git add .

# Commit changes
git commit -m "Update application"

# Push changes
git push origin main
```

## 11. Common CI/CD Troubleshooting

### Workflow is not running

Check:
- Workflow file is inside `.github/workflows/`.
- File extension is `.yml` or `.yaml`.
- Branch name matches the configured branch.
- GitHub Actions is enabled.

### Docker build failed

Check:
- Dockerfile syntax.
- Required files exist.
- Dependencies are installed correctly.
- Application builds successfully locally.

### Permission denied when pushing Docker image

Check:
- `packages: write` permission.
- GitHub Actions permissions.
- Container Registry authentication.

### SSH connection failed

Check:
- Server IP address.
- SSH username.
- Private SSH key.
- SSH port.
- Server firewall configuration.

### Application is not updating

Check:
- Docker image was successfully pushed.
- Production Compose file references the correct image.
- Server successfully pulled the latest image.
- Application container logs.

Useful commands:

```bash
docker compose ps

docker compose logs -f app

docker compose pull

docker compose up -d
```

## 12. Important Notes

- CI should run before deployment.
- Deploy only after successful tests and image builds.
- Never expose sensitive credentials.
- Use separate development and production environments.
- Keep database data in persistent Docker volumes.
- Use a reverse proxy such as Nginx or Caddy for production HTTPS and domain routing.
- Configure database backups before production deployment.
- Consider health checks and rollback procedures for production applications.

---

## Recommended Development Workflow

| Stage | Tool |
|---|---|
| Development | VS Code |
| Version Control | Git |
| Repository | GitHub |
| Automation | GitHub Actions |
| Testing | Jest / PHPUnit |
| Containerization | Docker |
| Image Registry | GitHub Container Registry |
| Deployment | SSH + Docker Compose |
| Reverse Proxy | Nginx / Caddy |
| Hosting