# 🚀 CI/CD Setup Guide gamit ang GitHub Actions, Docker, at VPS

Isang kumpletong gabay para sa awtomatikong pag-test, pag-build ng Docker image, at pag-deploy ng iyong application sa iyong live VPS server tuwing nagpu-push ka sa GitHub.

---

## 📌 Talaan ng Nilalaman
1. [Ano ang CI/CD sa Simpleng Salita?](#1-ano-ang-cicd-sa-simpleng-salita)
2. [Paano Gumagana ang Buong Deployment Pipeline?](#2-paano-gumagana-ang-buong-deployment-pipeline)
3. [Folder Structure sa Project Mo](#3-folder-structure-sa-project-mo)
4. [Ang Workflow File: .github/workflows/deploy.yml](#4-ang-workflow-file-githubworkflowsdeployyml)
5. [GitHub Secrets Checklist (Ano ang mga ito at saan kukunin)](#5-github-secrets-checklist-ano-ang-mga-ito-at-saan-kukunin)
6. [Production compose.yaml sa Iyong VPS](#6-production-composeyaml-sa-iyong-vps)
7. [Paghahanda sa VPS Server Bago Mag-deploy](#7-paghahanda-sa-vps-server-bago-mag-deploy)
8. [Mga Karaniwang Problema at Solusyon (Troubleshooting)](#8-mga-karaniwang-problema-at-solusyon-troubleshooting)

---

## 1. Ano ang CI/CD sa Simpleng Salita?

- **CI (Continuous Integration):** Tuwing mag-pu-push ka ng code sa GitHub, awtomatikong te-testingin ng GitHub Actions ang code mo at bubuuin ang bagong Docker image.
- **CD (Continuous Deployment):** Kapag pumasa ang test, kusa itong mag-ko-connect sa VPS server mo sa pamamagitan ng SSH para i-download ang bagong image at i-restart ang app nang walang downtime.
- **Resulta:** Hindi mo na kailangang mag-FTP, mag-manual SSH, o mag-upload ng files. Isang `git push origin main` lang, live na agad ang website mo!

---

## 2. Paano Gumagana ang Buong Deployment Pipeline?

```text
[Ikaw / Developer]
       │
       │ 1. git push origin main
       ▼
[GitHub Repository]
       │
       │ 2. Kusa itong magti-trigger ng GitHub Actions
       ▼
[GitHub Cloud Runner (Ubuntu)]
       ├─ Step A: Check-out ng code
       ├─ Step B: Patakbuhin ang tests (npm test)
       ├─ Step C: I-build ang Docker image
       └─ Step D: I-push ang image sa GitHub Container Registry (ghcr.io)
       │
       │ 3. Mag-co-connect via SSH sa iyong VPS Server
       ▼
[Production VPS / Cloud Server]
       ├─ Step E: I-download (docker compose pull) ang pinakabagong image
       ├─ Step F: I-restart ang container (docker compose up -d)
       └─ Step G: LIVE NA ANG BAGONG VERSION NG APP MO! 🎉
```

---

## 3. Folder Structure sa Project Mo

Sa loob ng iyong local project root directory:

```text
iyong-project/
├── .github/
│   └── workflows/
│       └── deploy.yml      <-- DITO NAKALAGAY ANG CI/CD PIPELINE
├── Dockerfile              <-- Production Dockerfile
├── compose.yaml            <-- Development compose file
├── .dockerignore
├── package.json
└── ...
```

---

## 4. Ang Workflow File: `.github/workflows/deploy.yml`

Gumawa ng file na `.github/workflows/deploy.yml` sa iyong repository:

```yaml
name: CI/CD Pipeline
# 👉 [PARA SAAN]: Pangalan ng pipeline na makikita sa GitHub Actions tab.
# 🔒 [WAG GALAWIN]

on:
  push:
    branches:
      - main
  # ✏️ [PAPALITAN MO]: Kung 'master' o 'production' ang default branch mo, palitan ang 'main'.
  # 👉 [PARA SAAN]: Tuwing may push sa branch na ito, awtomatikong tatakbo ang workflow.

  pull_request:
    branches:
      - main
  # 👉 [PARA SAAN]: Te-testingin din ang code kapag may nagbukas ng Pull Request.

env:
  REGISTRY: ghcr.io
  # 👉 [PARA SAAN]: GitHub Container Registry (libre at kasama na sa GitHub).
  # 🔒 [WAG GALAWIN]

  IMAGE_NAME: ${{ github.repository }}
  # 👉 [PARA SAAN]: Kusa nitong kukunin ang username/repo-name mo.
  # 🔒 [WAG GALAWIN]

jobs:
  # ============================================================================
  # JOB 1: TEST APPLICATION (CI)
  # ============================================================================
  test:
    name: Run Tests
    runs-on: ubuntu-latest
    # 🔒 [WAG GALAWIN]: Gumagamit ng official Ubuntu cloud runner ng GitHub.

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
      # 🔒 [WAG GALAWIN]: Kinokopya ang code mo sa cloud runner.

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
      # ✏️ [PAPALITAN MO]: Kung Node 18 o 20 ang gamit mo, palitan ang 22.
      #                    Kung PHP/Laravel: gamitin ang 'shivammathur/setup-php@v2'.

      - name: Install Dependencies
        run: npm ci
      # 👉 [PARA SAAN]: Malinis at mabilis na pag-install ng node_modules.

      - name: Run Tests
        run: npm test --if-present
      # 👉 [PARA SAAN]: Patatakbuhin ang tests kung may naka-define sa package.json.

      - name: Build Application
        run: npm run build
      # 👉 [PARA SAAN]: Sinusubukan kung magbi-build ang app nang walang TypeScript compile error.

  # ============================================================================
  # JOB 2: BUILD DOCKER IMAGE & PUSH SA REGISTRY (CI)
  # ============================================================================
  docker:
    name: Build and Push Docker Image
    runs-on: ubuntu-latest
    needs: test
    # 🔒 [WAG GALAWIN]: Hihintaying pumasa muna ang test bago mag-build.

    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    # 🔒 [WAG GALAWIN]: Tatakbo LANG kapag aktwal na push sa main branch (hindi sa PR).

    permissions:
      contents: read
      packages: write
    # 🔒 [WAG GALAWIN]: Permiso para makapag-upload ng image sa GitHub Packages.

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
      # 🔒 [WAG GALAWIN]: Auto-generated ng GitHub ang GITHUB_TOKEN para makapag-login.

      - name: Extract Metadata (Tags & Labels)
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            type=raw,value=latest
            type=sha
      # 🔒 [WAG GALAWIN]: Nilalagyan ng 'latest' tag ang image.

      - name: Build and Push Image
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
      # 👉 [PARA SAAN]: Binuo ang image gamit ang Dockerfile at in-upload sa ghcr.io.

  # ============================================================================
  # JOB 3: DEPLOY TO SERVER (CD)
  # ============================================================================
  deploy:
    name: Deploy Application
    runs-on: ubuntu-latest
    needs: docker
    # 🔒 [WAG GALAWIN]: Tatakbo lang kapag na-upload na ang bagong Docker image.

    steps:
      - name: Deploy Through SSH
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.SERVER_HOST }}
          # 👉 [PARA SAAN]: IP address ng VPS mo mula sa GitHub Secrets.

          username: ${{ secrets.SERVER_USER }}
          # 👉 [PARA SAAN]: SSH user mo sa VPS (hal. root o ubuntu).

          key: ${{ secrets.SERVER_SSH_KEY }}
          # 👉 [PARA SAAN]: Private SSH Key mo para makapag-login nang walang password.

          port: ${{ secrets.SERVER_PORT }}
          # 👉 [PARA SAAN]: SSH port (default ay 22).

          script: |
            cd ${{ secrets.APP_PATH }}
            # 👉 [PARA SAAN]: Pupunta sa folder ng project mo sa VPS.

            echo "${{ secrets.GHCR_READ_TOKEN }}" | docker login ghcr.io -u "${{ secrets.GHCR_USERNAME }}" --password-stdin
            # 👉 [PARA SAAN]: Nagla-login ang VPS sa GitHub Container Registry para ma-download ang image.

            docker compose pull
            # 👉 [PARA SAAN]: Dina-download ang bagong Docker image mula sa registry.

            docker compose up -d --remove-orphans
            # 👉 [PARA SAAN]: Nire-restart ang container gamit ang bagong version nang walang downtime!

            docker image prune -f
            # 👉 [PARA SAAN]: Nililinis ang mga lumang images para makatipid sa hard drive ng VPS.
```

---

## 5. GitHub Secrets Checklist (Ano ang mga ito at saan kukunin)

> 🔒 **Huwag ilalagay ang password o SSH keys sa code!**  
> Sa GitHub: Pumunta sa **Settings** ➔ **Secrets and variables** ➔ **Actions** ➔ **New repository secret**.

| Secret Name | Ano ang Ilalagay? | Halimbawa |
|---|---|---|
| `SERVER_HOST` | Public IP address ng VPS mo | `123.45.67.89` |
| `SERVER_USER` | SSH username sa VPS | `ubuntu` o `root` |
| `SERVER_SSH_KEY` | Ang buong **Private SSH Key** mo | Nagsisimula sa `-----BEGIN OPENSSH PRIVATE KEY-----` |
| `SERVER_PORT` | SSH port ng VPS mo | `22` |
| `APP_PATH` | Path ng folder ng project mo sa VPS | `/home/ubuntu/apps/my-project` |
| `GHCR_USERNAME` | Ang iyong GitHub Username | `KarlBrizuela` |
| `GHCR_READ_TOKEN` | GitHub Personal Access Token (classic) na may `read:packages` permission | `ghp_xxxxxx...` |

### 🔑 Paano Kunin ang mga Ito:
1. **Para sa `SERVER_SSH_KEY`:**
   - Sa terminal ng PC mo: `cat ~/.ssh/id_rsa`
   - I-copy lahat mula `-----BEGIN` hanggang `-----END`.
   - *Siguraduhing ang kapares nitong Public Key (`id_rsa.pub`) ay nakalagay sa `~/.ssh/authorized_keys` ng iyong VPS!*
2. **Para sa `GHCR_READ_TOKEN`:**
   - Sa GitHub: Profile picture ➔ **Settings** ➔ **Developer Settings** (kaliwang ibaba).
   - **Personal access tokens** ➔ **Tokens (classic)** ➔ **Generate new token (classic)**.
   - Lagyan ng check ang: `[x] read:packages`.
   - I-copy ang token at i-paste sa GitHub Secret.

---

## 6. Production `compose.yaml` sa Iyong VPS

Sa loob ng folder ng project mo sa VPS (ang folder na tinukoy sa `APP_PATH`), gumawa ng `compose.yaml`:

```yaml
services:
  app:
    # ✏️ [PAPALITAN MO]: Palitan ng sarili mong username at repository name:
    image: ghcr.io/karlbrizuela/my-project:latest
    container_name: production-app
    restart: unless-stopped
    ports:
      # ✏️ [PAPALITAN MO]: Kung gagamit ng Nginx reverse proxy sa harap:
      - "127.0.0.1:3000:3000"
    environment:
      - NODE_ENV=production
```

---

## 7. Paghahanda sa VPS Server Bago Mag-deploy

Bago mag-push sa GitHub sa unang pagkakataon, patakbuhin ito sa terminal ng iyong VPS:

```bash
# 1. Siguraduhing may Docker at Compose sa VPS
docker --version
docker compose version

# 2. Gumawa ng folder para sa iyong app
mkdir -p ~/apps/my-project
cd ~/apps/my-project

# 3. Gumawa ng compose.yaml sa loob nito
nano compose.yaml
# (I-paste ang template mula sa Seksyon 6, tapos Ctrl+O, Enter, Ctrl+X para i-save)
```

---

## 8. Mga Karaniwang Problema at Solusyon (Troubleshooting)

### ❓ Problema 1: "Permission denied (publickey)" sa SSH step
- **Dahilan:** Hindi tugma ang SSH key sa GitHub secret at sa VPS mo.
- **Solusyon:** Siguraduhing nailagay mo ang Public Key sa VPS:
  ```bash
  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/authorized_keys
  ```

### ❓ Problema 2: "denied: denied" kapag nagpu-pull ng image sa VPS
- **Dahilan:** Hindi naka-login ang VPS sa GitHub Container Registry.
- **Solusyon:** Sa VPS, mag-login nang manual gamit ang iyong Personal Access Token:
  ```bash
  echo "iyong-token" | docker login ghcr.io -u "iyong-username" --password-stdin
  ```

### ❓ Problema 3: "Failed to build image" sa GitHub Actions
- **Dahilan:** May build error sa TypeScript o kulang na files.
- **Solusyon:** I-test muna ang build sa local PC mo: `npm run build` o `docker compose build`.
