# CI/CD Setup Guide gamit ang GitHub Actions, Docker, at VPS

Gabay para sa awtomatikong pag-test, pag-build ng Docker image, at pag-deploy sa live VPS server tuwing nagpu-push sa GitHub.

---

## Talaan ng Nilalaman
1. [Konsepto ng CI/CD](#1-konsepto-ng-cicd)
2. [Paano Gumagana ang Deployment Pipeline](#2-paano-gumagana-ang-deployment-pipeline)
3. [Folder Structure sa Project](#3-folder-structure-sa-project)
4. [Ang Workflow File: .github/workflows/deploy.yml](#4-ang-workflow-file-githubworkflowsdeployyml)
5. [GitHub Secrets Checklist](#5-github-secrets-checklist)
6. [Production compose.yaml sa VPS](#6-production-composeyaml-sa-vps)
7. [Paghahanda sa VPS Server Bago Mag-deploy](#7-paghahanda-sa-vps-server-bago-mag-deploy)
8. [Mga Karaniwang Problema at Solusyon (Troubleshooting)](#8-mga-karaniwang-problema-at-solusyon-troubleshooting)

---

## 1. Konsepto ng CI/CD

- **CI (Continuous Integration):** Tuwing may bagong push sa GitHub repository, awtomatikong pinapatakbo ng GitHub Actions ang mga automated tests at binubuo ang bagong Docker container image.
- **CD (Continuous Deployment):** Kapag matagumpay ang tests at build, kusa itong kumokonekta sa iyong VPS server gamit ang SSH para i-pull ang bagong image at i-restart ang container nang walang downtime.
- **Resulta:** Hindi na kailangang mag-manual SSH, mag-FTP, o mag-rebuild sa mismong server. Isang `git push origin main` lang, updated na ang live production application.

---

## 2. Paano Gumagana ang Deployment Pipeline

```text
[Developer]
       │
       │ 1. git push origin main
       ▼
[GitHub Repository]
       │
       │ 2. Magti-trigger ng GitHub Actions
       ▼
[GitHub Cloud Runner (Ubuntu)]
       ├─ Step A: Check-out ng code
       ├─ Step B: Patakbuhin ang tests (npm test)
       ├─ Step C: I-build ang Docker image
       └─ Step D: I-push ang image sa GitHub Container Registry (ghcr.io)
       │
       │ 3. Mag-co-connect via SSH sa VPS
       ▼
[Production VPS Server]
       ├─ Step E: I-download (docker compose pull) ang pinakabagong image
       ├─ Step F: I-restart ang container (docker compose up -d)
       └─ Step G: Live na ang pinakabagong version ng application
```

---

## 3. Folder Structure sa Project

Sa loob ng iyong local project root directory:

```text
iyong-project/
├── .github/
│   └── workflows/
│       └── deploy.yml      # CI/CD pipeline definition
├── Dockerfile              # Production Dockerfile
├── compose.yaml            # Local development compose file
├── .dockerignore
├── package.json
└── ...
```

---

## 4. Ang Workflow File: `.github/workflows/deploy.yml`

Lumikha ng file sa `.github/workflows/deploy.yml` sa iyong repository:

```yaml
name: CI/CD Pipeline
# [PALIWANAG]: Pangalan ng pipeline sa GitHub Actions tab.
# [WAG GALAWIN]

on:
  push:
    branches:
      - main
  # [PAPALITAN MO]: Kung 'master' o 'production' ang pangalan ng default branch mo, palitan ang 'main'.
  # [PALIWANAG]: Tuwing may push sa branch na ito, magti-trigger ang workflow.

  pull_request:
    branches:
      - main
  # [PALIWANAG]: Tine-test din ang code kapag may nagbukas ng Pull Request sa main branch.

env:
  REGISTRY: ghcr.io
  # [PALIWANAG]: GitHub Container Registry; libre at built-in sa GitHub platform.
  # [WAG GALAWIN]

  IMAGE_NAME: ${{ github.repository }}
  # [PALIWANAG]: Awtomatikong kinukuha ang 'username/repo-name'.
  # [WAG GALAWIN]

jobs:
  # ============================================================================
  # JOB 1: TEST APPLICATION (CI)
  # ============================================================================
  test:
    name: Run Tests
    runs-on: ubuntu-latest
    # [WAG GALAWIN]: Gumagamit ng standard Ubuntu cloud runner.

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
      # [WAG GALAWIN]: Kinokopya ang code papunta sa runner machine.

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
      # [PAPALITAN MO]: Kung Node 18 o 20 ang gamit mo, palitan ang 22.
      #                 Kung PHP/Laravel ang project, gamitin ang 'shivammathur/setup-php@v2'.

      - name: Install Dependencies
        run: npm ci
      # [PALIWANAG]: Malinis at mabilis na pag-install base sa package-lock.json.

      - name: Run Tests
        run: npm test --if-present
      # [PALIWANAG]: Patatakbuhin ang test suite kung may naka-define sa package.json.

      - name: Build Application
        run: npm run build
      # [PALIWANAG]: Sinusuri kung magbi-build ang app nang walang syntax o compile errors.

  # ============================================================================
  # JOB 2: BUILD DOCKER IMAGE & PUSH SA REGISTRY (CI)
  # ============================================================================
  docker:
    name: Build and Push Docker Image
    runs-on: ubuntu-latest
    needs: test
    # [WAG GALAWIN]: Tatakbo lang kapag pumasa ang 'test' job.

    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    # [WAG GALAWIN]: Tumatakbo lang kapag aktwal na push sa main branch (hindi sa PR).

    permissions:
      contents: read
      packages: write
    # [WAG GALAWIN]: Permiso para makapag-upload ng image sa GitHub Packages.

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
      # [WAG GALAWIN]: Auto-generated ng GitHub ang GITHUB_TOKEN para sa registry authentication.

      - name: Extract Metadata (Tags at Labels)
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            type=raw,value=latest
            type=sha
      # [WAG GALAWIN]: Nilalagyan ng 'latest' tag at commit sha ang image.

      - name: Build and Push Image
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
      # [PALIWANAG]: Binubuo ang image gamit ang Dockerfile at ina-upload sa ghcr.io.

  # ============================================================================
  # JOB 3: DEPLOY TO SERVER (CD)
  # ============================================================================
  deploy:
    name: Deploy Application
    runs-on: ubuntu-latest
    needs: docker
    # [WAG GALAWIN]: Tatakbo lang kapag matagumpay na na-upload ang bagong image.

    steps:
      - name: Deploy Through SSH
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.SERVER_HOST }}
          # [PALIWANAG]: Public IP ng VPS mula sa GitHub Secrets.

          username: ${{ secrets.SERVER_USER }}
          # [PALIWANAG]: SSH user sa VPS (hal. root o ubuntu).

          key: ${{ secrets.SERVER_SSH_KEY }}
          # [PALIWANAG]: Private SSH key para makapasok nang walang interactive password.

          port: ${{ secrets.SERVER_PORT }}
          # [PALIWANAG]: SSH port ng server (karaniwan ay 22).

          script: |
            cd ${{ secrets.APP_PATH }}
            # [PALIWANAG]: Pupunta sa directory ng project sa VPS.

            echo "${{ secrets.GHCR_READ_TOKEN }}" | docker login ghcr.io -u "${{ secrets.GHCR_USERNAME }}" --password-stdin
            # [PALIWANAG]: Nagla-log in ang server sa GitHub Container Registry para ma-download ang image.

            docker compose pull
            # [PALIWANAG]: Dina-download ang pinakabagong Docker image.

            docker compose up -d --remove-orphans
            # [PALIWANAG]: Nire-restart ang container gamit ang bagong version.

            docker image prune -f
            # [PALIWANAG]: Nililinis ang mga lumang dangling images para makatipid sa storage.
```

---

## 5. GitHub Secrets Checklist

> **Paalala sa Seguridad:** Huwag i-commit ang mga sensitive keys o credentials sa code repository.  
> Sa GitHub: Pumunta sa **Settings** > **Secrets and variables** > **Actions** > **New repository secret**.

| Secret Name | Deskripsyon | Halimbawa |
|---|---|---|
| `SERVER_HOST` | Public IP address ng VPS | `123.45.67.89` |
| `SERVER_USER` | SSH username sa VPS | `ubuntu` o `root` |
| `SERVER_SSH_KEY` | Buong Private SSH Key | Nagsisimula sa `-----BEGIN OPENSSH PRIVATE KEY-----` |
| `SERVER_PORT` | SSH port ng VPS | `22` |
| `APP_PATH` | Absolute path ng project directory sa VPS | `/home/ubuntu/apps/my-project` |
| `GHCR_USERNAME` | GitHub Username mo | `KarlBrizuela` |
| `GHCR_READ_TOKEN` | GitHub Personal Access Token (classic) na may `read:packages` | `ghp_xxxxxx...` |

### Paano Kunin ang Credentials:
1. **Para sa `SERVER_SSH_KEY`:**
   - Sa terminal ng iyong local machine: `cat ~/.ssh/id_rsa`
   - Kopyahin ang buong nilalaman mula `-----BEGIN` hanggang `-----END`.
   - Siguraduhing ang kapares nitong Public Key (`id_rsa.pub`) ay nakalagay sa `~/.ssh/authorized_keys` sa iyong VPS.
2. **Para sa `GHCR_READ_TOKEN`:**
   - Sa GitHub: Profile icon > **Settings** > **Developer Settings** (kaliwang ibaba).
   - Pumunta sa **Personal access tokens** > **Tokens (classic)** > **Generate new token (classic)**.
   - Piliin ang scope na: `[x] read:packages`.
   - Kopyahin ang nabuong token at i-save bilang repository secret.

---

## 6. Production compose.yaml sa VPS

Sa loob ng directory ng project sa VPS (tinukoy sa `APP_PATH`), lumikha ng `compose.yaml`:

```yaml
services:
  app:
    # [PAPALITAN MO]: Palitan ng sarili mong username at repository name:
    image: ghcr.io/karlbrizuela/my-project:latest
    container_name: production-app
    restart: unless-stopped
    ports:
      # [PAPALITAN MO]: Kung gagamit ng Nginx reverse proxy sa harap:
      - "127.0.0.1:3000:3000"
    environment:
      - NODE_ENV=production
```

---

## 7. Paghahanda sa VPS Server Bago Mag-deploy

Bago mag-push sa GitHub sa unang pagkakataon, patakbuhin ang sumusunod sa terminal ng iyong VPS:

```bash
# 1. Siguraduhing naka-install ang Docker at Docker Compose
docker --version
docker compose version

# 2. Lumikha ng folder para sa iyong application
mkdir -p ~/apps/my-project
cd ~/apps/my-project

# 3. Gumawa ng compose.yaml sa loob ng folder na ito
nano compose.yaml
# (I-paste ang template mula sa Seksyon 6, tapos Ctrl+O, Enter, Ctrl+X para i-save)
```

---

## 8. Mga Karaniwang Problema at Solusyon (Troubleshooting)

### Problema 1: "Permission denied (publickey)" sa SSH step
- **Dahilan:** Hindi tugma ang SSH key sa GitHub secret at sa authorized keys ng VPS.
- **Solusyon:** Siguraduhing nailagay ang Public Key sa server:
  ```bash
  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/authorized_keys
  ```

### Problema 2: "denied: denied" kapag nagpu-pull ng image sa VPS
- **Dahilan:** Hindi pa naka-authenticate ang VPS sa GitHub Container Registry.
- **Solusyon:** Sa VPS, mag-login gamit ang Personal Access Token:
  ```bash
  echo "iyong-token" | docker login ghcr.io -u "iyong-username" --password-stdin
  ```

### Problema 3: "Failed to build image" sa GitHub Actions
- **Dahilan:** May TypeScript o syntax error sa application build.
- **Solusyon:** I-test muna ang build locally sa iyong machine: `npm run build` o `docker compose build`.
