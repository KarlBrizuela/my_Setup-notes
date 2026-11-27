#!/usr/bin/env bash

# ==============================================================================
# 🚀 GABAY AT SETUP SCRIPT PARA SA CI/CD (GitHub Actions + Docker + VPS)
# ==============================================================================
# Ano ang CI/CD sa simpleng salita?
#  - CI (Continuous Integration): Kusa/Awtomatikong te-testingin at bubuuin 
#    ang Docker image ng app mo tuwing may bago kang "git push".
#  - CD (Continuous Deployment): Kusa/Awtomatikong pupunta sa VPS/Cloud Server 
#    mo gamit ang SSH, i-da-download ang bagong image, at i-re-restart ang container.
#
# Resulta: Hindi mo na kailangang mag-manual upload o mag-manual SSH tuwing may 
#          pagbabago sa code mo. Git push lang sa "main" branch, live na agad!
# ==============================================================================

set -e

# Mga Kulay para maganda sa terminal
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
print_edit()    { echo -e "${YELLOW}✏️  [PAPALITAN MO]${NC} $1"; }
print_stay()    { echo -e "${GREEN}🔒 [WAG GALAWIN]${NC} $1"; }

# ------------------------------------------------------------------------------
# 1. PALIWANAG: PAANO GUMAGANA ANG WORKFLOW STEP-BY-STEP
# ------------------------------------------------------------------------------
show_overview() {
    print_title "PAANO GUMAGANA ANG BUONG CI/CD PIPELINE"
    cat << 'EOF'
[Ikaw / Developer]
       │
       │ 1. Git push origin main
       ▼
[GitHub Repository]
       │
       │ 2. Kusa itong magti-trigger ng GitHub Actions
       ▼
[GitHub Actions Cloud Server (Ubuntu Runner)]
       ├─ Step A: Check-out ng code mo
       ├─ Step B: Patakbuhin ang tests (npm test / php artisan test)
       ├─ Step C: I-build ang Docker image
       └─ Step D: I-upload (push) ang image sa GitHub Container Registry (ghcr.io)
       │
       │ 3. Mag-co-connect via SSH sa iyong VPS Server
       ▼
[Production VPS / Cloud Server]
       ├─ Step E: I-download (docker pull) ang pinakabagong image
       ├─ Step F: I-restart ang container (docker compose up -d)
       └─ Step G: LIVE NA ANG BAGONG VERSION NG APP MO! 🎉
EOF
}

# ------------------------------------------------------------------------------
# 2. PALIWANAG KADA LINYA: .github/workflows/deploy.yml
# ------------------------------------------------------------------------------
show_workflow_explanation() {
    print_title "PALIWANAG KADA LINYA SA: .github/workflows/deploy.yml"

    cat << 'EOF'
Nasa ibaba ang buong code ng deploy.yml na may kasamang turo sa bawat linya.
Tingnan maigi ang mga marka:
  ✏️ [PAPALITAN MO] = Kailangan mong baguhin ayon sa project mo.
  🔒 [WAG GALAWIN]  = Standard GitHub Actions syntax, iwanan lang.

--------------------------------------------------------------------------------
name: CI/CD Pipeline
# 👉 [PALIWANAG]: Pangalan ng workflow na makikita mo sa GitHub Actions tab.
# 🔒 [WAG GALAWIN]

on:
  push:
    branches:
      - main
# 👉 [PALIWANAG]: Tuwing magpu-push ka sa 'main' branch, aandar ang workflow.
# ✏️ [PAPALITAN MO]: Kung 'master' o 'production' ang gamit mong branch, palitan ang 'main'.

  pull_request:
    branches:
      - main
# 👉 [PALIWANAG]: Te-testingin din ang code kapag may nagbukas ng Pull Request sa main.

env:
  REGISTRY: ghcr.io
# 👉 [PALIWANAG]: Dito ise-save ang Docker image (GitHub Container Registry). Libre ito sa GitHub!
# 🔒 [WAG GALAWIN]

  IMAGE_NAME: ${{ github.repository }}
# 👉 [PALIWANAG]: Kusa nitong kukunin ang pangalan ng repo mo (hal. username/my-app).
# 🔒 [WAG GALAWIN]

jobs:
# ==============================================================================
# JOB 1: TEST APPLICATION (CI - Continuous Integration)
# ==============================================================================
  test:
    name: Run Tests
    runs-on: ubuntu-latest
# 👉 [PALIWANAG]: Bubuo ang GitHub ng pansamantalang Ubuntu machine sa cloud.
# 🔒 [WAG GALAWIN]

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
# 👉 [PALIWANAG]: Kinokopya ang buong source code mo papunta sa runner machine.
# 🔒 [WAG GALAWIN]

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
# 👉 [PALIWANAG]: Ini-install ang Node.js version 22 sa cloud runner.
# ✏️ [PAPALITAN MO]: Kung Node 18 o 20 ang gamit mo, palitan ang '22'.
#                     Kung Laravel/PHP ang project mo, palitan ito ng 'shivammathur/setup-php@v2'.

      - name: Install Dependencies
        run: npm ci
# 👉 [PALIWANAG]: Malinis na pag-install ng node_modules base sa package-lock.json.
# ✏️ [PAPALITAN MO]: Kung composer/PHP: 'composer install --no-interaction'.

      - name: Run Tests
        run: npm test --if-present
# 👉 [PALIWANAG]: Papatakbuhin ang unit tests mo kung meron man. Kung walang test, hindi mag-e-error.
# 🔒 [WAG GALAWIN]

      - name: Build Application
        run: npm run build
# 👉 [PALIWANAG]: Sinusubukang i-build ang app para masiguradong walang TypeScript o compile error.
# ✏️ [PAPALITAN MO]: Kung walang build step ang project mo, pwede itong tanggalin.

# ==============================================================================
# JOB 2: BUILD DOCKER IMAGE & PUSH SA REGISTRY (CI)
# ==============================================================================
  docker:
    name: Build and Push Docker Image
    runs-on: ubuntu-latest
    needs: test
# 👉 [PALIWANAG]: Hindi ito tatakbo hangga't HINDI pumapasa ang 'test' job sa itaas.
# 🔒 [WAG GALAWIN]

    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
# 👉 [PALIWANAG]: Mag-bi-build at push LANG kung aktwal na push sa 'main' branch (hindi sa PR).
# 🔒 [WAG GALAWIN]

    permissions:
      contents: read
      packages: write
# 👉 [PALIWANAG]: Binibigyan ng permiso ang workflow para makapag-upload sa GitHub Packages.
# 🔒 [WAG GALAWIN]

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
# 🔒 [WAG GALAWIN]

      - name: Setup Docker Buildx
        uses: docker/setup-buildx-action@v3
# 👉 [PALIWANAG]: Ini-enable ang modern Docker Buildx para mabilis at may caching.
# 🔒 [WAG GALAWIN]

      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
# 👉 [PALIWANAG]: Nagla-log in sa container registry gamit ang auto-generated token ng GitHub.
# 🔒 [WAG GALAWIN] (Awtomatikong binibigay ng GitHub ang GITHUB_TOKEN).

      - name: Extract Metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            type=raw,value=latest
            type=sha
# 👉 [PALIWANAG]: Nilalagyan ng tags ang Docker image ('latest' at git commit hash).
# 🔒 [WAG GALAWIN]

      - name: Build and Push Image
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
# 👉 [PALIWANAG]: Dito na aktwal na binuo ang Docker image base sa Dockerfile mo at in-upload sa cloud!
# 🔒 [WAG GALAWIN]

# ==============================================================================
# JOB 3: DEPLOY TO SERVER (CD - Continuous Deployment)
# ==============================================================================
  deploy:
    name: Deploy Application
    runs-on: ubuntu-latest
    needs: docker
# 👉 [PALIWANAG]: Tatakbo LANG ito pagkatapos ma-upload ang bagong Docker image sa cloud.
# 🔒 [WAG GALAWIN]

    steps:
      - name: Deploy Through SSH
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.SERVER_HOST }}
# 👉 [PALIWANAG]: IP address ng VPS mo (kinukuha sa GitHub Secrets para ligtas).

          username: ${{ secrets.SERVER_USER }}
# 👉 [PALIWANAG]: SSH username mo sa server (halimbawa: root o ubuntu).

          key: ${{ secrets.SERVER_SSH_KEY }}
# 👉 [PALIWANAG]: Ang Private SSH Key mo para makapasok ang GitHub sa server nang walang password.

          port: ${{ secrets.SERVER_PORT }}
# 👉 [PALIWANAG]: SSH port ng server mo (karaniwan ay port 22).

          script: |
            cd ${{ secrets.APP_PATH }}
# 👉 [PALIWANAG]: Pupunta sa folder ng project mo sa VPS (halimbawa: /home/ubuntu/my-app).

            echo "${{ secrets.GHCR_READ_TOKEN }}" | docker login ghcr.io -u "${{ secrets.GHCR_USERNAME }}" --password-stdin
# 👉 [PALIWANAG]: Nagla-log in ang VPS mo sa GitHub Container Registry para ma-download ang image.

            docker compose pull
# 👉 [PALIWANAG]: Dina-download ang pinakabagong Docker image na kaka-upload lang.

            docker compose up -d --remove-orphans
# 👉 [PALIWANAG]: Nirere-start ang app gamit ang bagong version nang WALANG downtime!

            docker image prune -f
# 👉 [PALIWANAG]: Nililinis ang mga lumang Docker images sa VPS para hindi mapuno ang disk space.
--------------------------------------------------------------------------------
EOF
}

# ------------------------------------------------------------------------------
# 3. PALIWANAG: GITHUB SECRETS (Ano ang mga ilalagay at saan kukunin)
# ------------------------------------------------------------------------------
show_secrets_guide() {
    print_title "GABAY SA GITHUB SECRETS: ANO ANG MGA ITO AT SAAN KUKUNIN?"
    cat << 'EOF'
⚠️  NAPAKAHALAGA: Huwag na huwag ilalagay ang password, IP, o SSH private key 
    nang direkta sa loob ng code! Sa GitHub Secrets ito inilalagay.

Saan ito ise-set sa GitHub?
  1. Buksan ang GitHub Repository mo sa browser.
  2. I-click ang: Settings (sa bandang taas)
  3. Sa kaliwang menu, i-click: Secrets and variables ➔ Actions
  4. I-click ang berdeng button: "New repository secret"

Ito ang 7 secrets na dapat mong ilagay:
--------------------------------------------------------------------------------
1. SERVER_HOST
   ✏️ [ILALAGAY]: Ang Public IP address ng VPS mo.
   📌 Halimbawa: 123.45.67.89

2. SERVER_USER
   ✏️ [ILALAGAY]: Ang username na ginagamit mo sa pag-SSH sa VPS.
   📌 Halimbawa: ubuntu o root

3. SERVER_SSH_KEY
   ✏️ [ILALAGAY]: Ang BUONG PRIVATE SSH KEY mo (nagsisimula sa -----BEGIN OPENSSH PRIVATE KEY-----).
   📌 Paano kunin sa PC mo?
      - Sa terminal, patakbuhin: cat ~/.ssh/id_rsa (o kung anong key name mo)
      - I-copy lahat mula BEGIN hanggang END line.
   📌 PAALALA: Siguraduhing ang kapares nitong PUBLIC KEY (.pub) ay nasa ~/.ssh/authorized_keys ng VPS mo!

4. SERVER_PORT
   ✏️ [ILALAGAY]: SSH port ng VPS mo.
   📌 Halimbawa: 22 (default)

5. APP_PATH
   ✏️ [ILALAGAY]: Ang absolute path ng folder ng app mo sa loob ng VPS.
   📌 Halimbawa: /home/ubuntu/apps/my-project

6. GHCR_USERNAME
   ✏️ [ILALAGAY]: Ang iyong GitHub Username (halimbawa: KarlBrizuela).

7. GHCR_READ_TOKEN
   ✏️ [ILALAGAY]: GitHub Personal Access Token (Classic).
   📌 Paano gawin sa GitHub?
      - GitHub Profile Photo (top right) ➔ Settings
      - Developer settings (kaliwang ibaba) ➔ Personal access tokens ➔ Tokens (classic)
      - I-click: "Generate new token (classic)"
      - Lagyan ng note (hal. "VPS Deployment Token")
      - Lagyan ng tsek ang: [x] read:packages
      - I-click Generate, at i-copy ang token (isang beses lang ito ipapakita ng GitHub!).
--------------------------------------------------------------------------------
EOF
}

# ------------------------------------------------------------------------------
# 4. PALIWANAG: PRODUCTION COMPOSE.YAML SA VPS
# ------------------------------------------------------------------------------
show_compose_explanation() {
    print_title "PALIWANAG KADA LINYA: PRODUCTION compose.yaml SA VPS"
    cat << 'EOF'
Sa loob ng iyong VPS (sa folder na tinukoy sa APP_PATH), kailangan mayroong compose.yaml.
Ito ang magsasabi sa Docker kung anong image ang kukunin at paano patakbuhin.

--------------------------------------------------------------------------------
services:
  app:
    image: ghcr.io/karlbrizuela/my-project:latest
# ✏️ [PAPALITAN MO]: Palitan ang 'karlbrizuela/my-project' ng:
#                    ghcr.io/<iyong-github-username>/<iyong-repository-name>:latest
# 👉 [PALIWANAG]: Ito yung image na ginawa at in-upload ng GitHub Actions pipeline mo.

    container_name: production-app
# ✏️ [PAPALITAN MO]: Pangalan ng container na gusto mo (hal. myapp-web).
# 👉 [PALIWANAG]: Pangalan para madaling makita sa 'docker ps'.

    restart: unless-stopped
# 🔒 [WAG GALAWIN]
# 👉 [PALIWANAG]: Kung sakaling mag-reboot ang VPS server mo, kusang magre-restart ang app!

    ports:
      - "3000:3000"
# ✏️ [PAPALITAN MO]: Format: "HOST_PORT:CONTAINER_PORT"
#                    - Ang kaliwa ("3000") ay ang port sa server mo.
#                    - Ang kanan ("3000") ay ang port sa loob ng Docker container.
# 👉 [PALIWANAG]: Kung gagamit ka ng Nginx reverse proxy sa harap, pwede itong: "127.0.0.1:3000:3000"
#                    para hindi direktang ma-access ng publiko ang container nang hindi dumadaan sa Nginx.

    environment:
      - NODE_ENV=production
# 👉 [PALIWANAG]: Sinasabi sa app na nasa live production mode ito para mas mabilis at optimized.
--------------------------------------------------------------------------------
EOF
}

# ------------------------------------------------------------------------------
# 5. GENERATOR: KUSANG GAGAWA NG MGA FILES PARA SA IYO
# ------------------------------------------------------------------------------
generate_workflow_file() {
    print_title "GUMAWA NG GITHUB ACTIONS WORKFLOW FILE"

    read -rp "Ilagay ang branch na magti-trigger ng deploy (Default: main): " branch_name
    branch_name=${branch_name:-main}

    read -rp "Anong runtime? (1: Node.js 22, 2: Node.js 20, 3: PHP/Laravel) [Default: 1]: " runtime_choice
    runtime_choice=${runtime_choice:-1}

    local workflow_dir=".github/workflows"
    mkdir -p "$workflow_dir"

    local target_file="$workflow_dir/deploy.yml"

    cat << EOF > "$target_file"
name: CI/CD Pipeline

on:
  push:
    branches:
      - ${branch_name}
  pull_request:
    branches:
      - ${branch_name}

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: \${{ github.repository }}

jobs:
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

  docker:
    name: Build and Push Docker Image
    runs-on: ubuntu-latest
    needs: test
    if: github.event_name == 'push' && github.ref == 'refs/heads/${branch_name}'
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
          username: \${{ github.actor }}
          password: \${{ secrets.GITHUB_TOKEN }}

      - name: Extract Metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/\${{ github.repository }}
          tags: |
            type=raw,value=latest
            type=sha

      - name: Build and Push Image
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: \${{ steps.meta.outputs.tags }}
          labels: \${{ steps.meta.outputs.labels }}

  deploy:
    name: Deploy Application
    runs-on: ubuntu-latest
    needs: docker
    steps:
      - name: Deploy Through SSH
        uses: appleboy/ssh-action@v1
        with:
          host: \${{ secrets.SERVER_HOST }}
          username: \${{ secrets.SERVER_USER }}
          key: \${{ secrets.SERVER_SSH_KEY }}
          port: \${{ secrets.SERVER_PORT }}
          script: |
            cd \${{ secrets.APP_PATH }}
            echo "\${{ secrets.GHCR_READ_TOKEN }}" | docker login ghcr.io -u "\${{ secrets.GHCR_USERNAME }}" --password-stdin
            docker compose pull
            docker compose up -d --remove-orphans
            docker image prune -f
EOF

    print_success "Nagawa na ang file: $target_file!"
}

generate_production_compose() {
    print_title "GUMAWA NG PRODUCTION compose.yaml PARA SA VPS"

    read -rp "Ilagay ang iyong GitHub Username (hal. KarlBrizuela): " gh_user
    read -rp "Ilagay ang Repository Name (hal. my-app): " repo_name
    read -rp "Anong port ang gagamitin sa host server? [Default: 3000]: " host_port
    host_port=${host_port:-3000}
    read -rp "Anong port sa loob ng container? [Default: 3000]: " container_port
    container_port=${container_port:-3000}

    local target_compose="compose.production.yaml"

    cat << EOF > "$target_compose"
services:
  app:
    image: ghcr.io/${gh_user,,}/${repo_name,,}:latest
    container_name: ${repo_name,,}-production
    restart: unless-stopped
    ports:
      - "${host_port}:${container_port}"
    environment:
      - NODE_ENV=production
EOF

    print_success "Nagawa na ang production template: $target_compose!"
    echo "I-upload o kopyahin ang file na ito papunta sa iyong VPS sa loob ng APP_PATH folder."
}

# ------------------------------------------------------------------------------
# 6. INTERACTIVE MENU
# ------------------------------------------------------------------------------
show_menu() {
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${GREEN}    CI/CD SETUP & GABAY SA GITHUB ACTIONS + DOCKER    ${NC}"
    echo -e "${BLUE}======================================================${NC}"
    echo " 1) Paano gumagana ang CI/CD? (Overview Diagram)"
    echo " 2) Paliwanag Kada Linya sa: deploy.yml (Alin ang papalitan)"
    echo " 3) Gabay sa GitHub Secrets (Ano ang mga ilalagay at saan kukunin)"
    echo " 4) Paliwanag Kada Linya sa: Production compose.yaml"
    echo "------------------------------------------------------"
    echo " 5) Kusang gumawa ng .github/workflows/deploy.yml"
    echo " 6) Kusang gumawa ng compose.production.yaml para sa VPS"
    echo " 0) Exit"
    echo -e "${BLUE}======================================================${NC}"
    read -rp "Pumili ng numero [0-6]: " choice

    case "$choice" in
        1) show_overview ;;
        2) show_workflow_explanation ;;
        3) show_secrets_guide ;;
        4) show_compose_explanation ;;
        5) generate_workflow_file ;;
        6) generate_production_compose ;;
        0) exit 0 ;;
        *) print_error "Maling numero. Pumili mula 0 hanggang 6.";;
    esac
}

# ------------------------------------------------------------------------------
# ENTRY POINT
# ------------------------------------------------------------------------------
case "$1" in
    overview)       show_overview ;;
    workflow)       show_workflow_explanation ;;
    secrets)        show_secrets_guide ;;
    compose)        show_compose_explanation ;;
    generate)       generate_workflow_file ;;
    gen-compose)    generate_production_compose ;;
    help|--help|-h)
        echo "Gamit: ./CI/CD_setup.sh [command]"
        echo ""
        echo "Mga Command:"
        echo "  overview    Tingnan ang diagram kung paano gumagana ang CI/CD"
        echo "  workflow    Paliwanag kada linya sa deploy.yml"
        echo "  secrets     Listahan ng mga kailangang GitHub Secrets"
        echo "  compose     Paliwanag kada linya sa production compose.yaml"
        echo "  generate    Kusang lumikha ng .github/workflows/deploy.yml"
        echo "  gen-compose Kusang lumikha ng compose.production.yaml"
        echo "  (walang arg) Bubuksan ang interactive Tagalog menu"
        ;;
    *)
        if [ -n "$1" ]; then
            print_error "Hindi kilalang utos: $1"
            echo "Patakbuhin ang './CI/CD_setup.sh help' para sa gabay."
            exit 1
        else
            show_menu
        fi
        ;;
esac
