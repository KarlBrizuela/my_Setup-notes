#!/usr/bin/env bash

# ==============================================================================
# 🌐 GABAY AT SETUP SCRIPT PARA SA NGINX (Reverse Proxy + SSL Certbot)
# ==============================================================================
# Ano ang Nginx at bakit natin ito kailangan?
#  - Sa production, HINDI natin basta binubuksan ang internal port ng Docker
#    (tulad ng 3000 o 8000) sa buong internet.
#  - Si Nginx ang nagsisilbing "Guard / Traffic Enforcer" (Reverse Proxy).
#  - Lahat ng bisita sa internet dadaan sa port 80 (HTTP) o port 443 (HTTPS).
#  - Si Nginx ang magpapasa ng request papasok sa Docker container mo
#    (proxy_pass http://127.0.0.1:3000).
#
# Bakit kailangan ng Nginx?
#  1. Libreng SSL / Padlock 🔒 gamit ang Let's Encrypt (Certbot).
#  2. Custom Domain (hal. myproject.com sa halip na http://123.45.67.89:3000).
#  3. Maraming Apps sa iisang Server (hal. app.domain.com -> Port 3000, 
#     api.domain.com -> Port 8000).
# ==============================================================================

set -e

# Mga Kulay
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

# ------------------------------------------------------------------------------
# 1. PALIWANAG: PAANO GUMAGANA ANG REVERSE PROXY
# ------------------------------------------------------------------------------
show_overview() {
    print_title "PAANO GUMAGANA ANG NGINX REVERSE PROXY"
    cat << 'EOF'
[User sa Internet (Browser)]
       │
       │ Nag-type ng: https://myproject.com
       ▼
[Nginx sa Port 80 / 443 (May SSL / HTTPS)]
       │
       │ Sinasala at pinapasa ang request (proxy_pass)
       ▼
[Docker Container sa loob ng Server (Port 3000 o 8000)]
       │
       │ Pinoproseso ang Next.js o Laravel code
       ▼
[Ibabalik ang tugon papunta sa User sa Browser] 🎉
EOF
}

# ------------------------------------------------------------------------------
# 2. PALIWANAG KADA LINYA: NGINX CONFIGURATION FILE
# ------------------------------------------------------------------------------
show_config_explanation() {
    print_title "PALIWANAG KADA LINYA SA NGINX CONFIG (/etc/nginx/sites-available/myapp.conf)"
    cat << 'EOF'
Ito ang karaniwang Nginx configuration file para sa isang Dockerized project.
Tingnan maigi ang mga marka kung alin ang papalitan mo:

--------------------------------------------------------------------------------
server {
# 👉 [PALIWANAG]: Simula ng server block para sa isang website/domain.
# 🔒 [WAG GALAWIN]

    listen 80;
    listen [::]:80;
# 👉 [PALIWANAG]: Nakikinig sa port 80 (ang default port ng HTTP sa internet).
# 🔒 [WAG GALAWIN]

    server_name myproject.com www.myproject.com;
# ✏️ [PAPALITAN MO]: Ilagay dito ang tunay mong domain o subdomain na binili mo.
#                    Kung wala pang domain at IP lang, ilagay ang IP ng VPS (hal. 123.45.67.89;).
# 👉 [PALIWANAG]: Sinasabi kay Nginx na kapag may nag-request para sa domain na ito, dito pupunta.

    client_max_body_size 50M;
# ✏️ [PAPALITAN MO]: Maximum file size na pwedeng i-upload ng users sa website mo (hal. 10M, 50M, 100M).
# 👉 [PALIWANAG]: Kung mag-a-upload ka ng images o videos, hindi ito iba-block ni Nginx.

    location / {
# 👉 [PALIWANAG]: Sinasakop ang lahat ng URL path (lahat ng requests na papasok).
# 🔒 [WAG GALAWIN]

        proxy_pass http://127.0.0.1:3000;
# ✏️ [PAPALITAN MO]: ANG PINAKAMAHALAGANG LINYA!
#                    - Palitan ang '3000' ng port kung saan tumatakbo ang Docker container mo.
#                    - Kung Next.js: karaniwan ay 3000.
#                    - Kung Laravel: karaniwan ay 8000.
# 👉 [PALIWANAG]: Ipinapasa ni Nginx ang request papunta sa local Docker port mo.

        proxy_http_version 1.1;
# 👉 [PALIWANAG]: Gumagamit ng HTTP/1.1 protocol para sa mabilis na koneksyon at WebSockets.
# 🔒 [WAG GALAWIN]

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
# 👉 [PALIWANAG]: Para sa Next.js HMR (Hot Module Replacement) at WebSockets / Live chats.
# 🔒 [WAG GALAWIN]

        proxy_set_header Host $host;
# 👉 [PALIWANAG]: Ipinapasa ang orihinal na domain name papasok sa container mo.
# 🔒 [WAG GALAWIN]

        proxy_set_header X-Real-IP $remote_addr;
# 👉 [PALIWANAG]: Ipinapasa ang totoong IP address ng bumibisita (kung hindi ito ilalagay, 
#                    aakalain ng app mo na 127.0.0.1 ang IP ng lahat ng user!).
# 🔒 [WAG GALAWIN]

        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
# 👉 [PALIWANAG]: Sinasabi sa app kung HTTP o HTTPS ang ginamit ng user.
# 🔒 [WAG GALAWIN]

        proxy_cache_bypass $http_upgrade;
# 🔒 [WAG GALAWIN]
    }
}
--------------------------------------------------------------------------------
EOF
}

# ------------------------------------------------------------------------------
# 3. GABAY: STEP-BY-STEP SETUP SA UBUNTU VPS
# ------------------------------------------------------------------------------
show_vps_setup_guide() {
    print_title "STEP-BY-STEP SETUP NG NGINX SA IYONG VPS (UBUNTU / DEBIAN)"
    cat << 'EOF'
Sundin ang mga hakbang na ito sa loob ng terminal ng iyong VPS:

HAKBANG 1: I-install ang Nginx
  sudo apt update
  sudo apt install nginx -y

HAKBANG 2: Siguraduhing tumatakbo ang Nginx
  sudo systemctl start nginx
  sudo systemctl enable nginx
  sudo systemctl status nginx

HAKBANG 3: Gumawa ng Configuration File para sa Project mo
  sudo nano /etc/nginx/sites-available/myproject.conf

  (I-paste ang template sa taas, palitan ang server_name at proxy_pass port, tapos i-save: Ctrl+O, Enter, Ctrl+X)

HAKBANG 4: I-activate ang configuration (Gumawa ng symlink)
  sudo ln -s /etc/nginx/sites-available/myproject.conf /etc/nginx/sites-enabled/

HAKBANG 5: I-test kung walang error ang syntax ng Nginx
  sudo nginx -t
  (Dapat lumabas: "syntax is ok" at "test is successful")

HAKBANG 6: I-reload ang Nginx para magkabisa ang bagong config
  sudo systemctl reload nginx
EOF
}

# ------------------------------------------------------------------------------
# 4. GABAY: LIBRENG SSL / HTTPS GAMIT ANG CERTBOT
# ------------------------------------------------------------------------------
show_ssl_guide() {
    print_title "PAANO LAGYAN NG LIBRENG SSL / HTTPS (PADLOCK 🔒) GAMIT ANG CERTBOT"
    cat << 'EOF'
Kapag may sarili ka nang domain name na nakaturo sa IP ng VPS mo (A Record sa DNS):

HAKBANG 1: I-install ang Certbot at Nginx plugin
  sudo apt update
  sudo apt install certbot python3-certbot-nginx -y

HAKBANG 2: Humingi ng SSL Certificate para sa iyong domain
  sudo certbot --nginx -d myproject.com -d www.myproject.com

  (May itatanong sa iyo ang Certbot):
  1. Email Address: Ilagay ang email mo (para sa security notices).
  2. Terms of Service: Type 'Y' at Enter.
  3. Share email?: Pwedeng 'N'.
  4. Automatic Redirect HTTP to HTTPS?: Piliin ang '2' (Redirect - Recommended).

HAKBANG 3: Kusa nang babaguhin ng Certbot ang iyong Nginx config!
  - Magiging HTTPS na ang site mo: https://myproject.com
  - May padlock 🔒 na agad sa browser!

PAALALA SA SSL RENEWAL:
  Libre ang Let's Encrypt certificate sa loob ng 90 days, pero KUSA itong 
  ina-auto-renew ng Certbot bago mag-expire!
  Para masubukan kung gagana ang auto-renew:
    sudo certbot renew --dry-run
EOF
}

# ------------------------------------------------------------------------------
# 5. KUSANG GUMAWA NG NGINX CONFIG FILE (GENERATOR)
# ------------------------------------------------------------------------------
generate_nginx_config() {
    print_title "AUTOMATIC NGINX CONFIG FILE GENERATOR"

    read -rp "Ilagay ang Domain Name mo (hal. myapp.com o test.example.com): " domain_name
    if [ -z "$domain_name" ]; then
        print_warn "Walang domain? Gagamitin ang default: localhost"
        domain_name="localhost"
    fi

    read -rp "Anong local port ng Docker container mo? (hal. 3000 para sa Next.js, 8000 para sa Laravel) [Default: 3000]: " app_port
    app_port=${app_port:-3000}

    read -rp "Max upload file size? [Default: 50M]: " max_size
    max_size=${max_size:-50M}

    local output_file="nginx_${domain_name//./_}.conf"

    cat << EOF > "$output_file"
server {
    listen 80;
    listen [::]:80;

    # Ang iyong domain name
    server_name ${domain_name} www.${domain_name};

    # Maximum upload size
    client_max_body_size ${max_size};

    location / {
        # Port ng iyong Docker container
        proxy_pass http://127.0.0.1:${app_port};

        # Standard proxy headers para sa seguridad at WebSockets
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;

        # Timeout settings para hindi mag-time out ang mabibigat na requests
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

    print_success "Nagawa na ang config file: $output_file"
    echo ""
    print_info "Paano ito i-apply sa VPS mo?"
    echo "  1. Kopyahin ang laman ng file na ito papunta sa VPS:"
    echo "     sudo nano /etc/nginx/sites-available/${domain_name}.conf"
    echo "  2. I-link sa sites-enabled:"
    echo "     sudo ln -s /etc/nginx/sites-available/${domain_name}.conf /etc/nginx/sites-enabled/"
    echo "  3. I-test at i-reload:"
    echo "     sudo nginx -t && sudo systemctl reload nginx"
    echo ""
}

# ------------------------------------------------------------------------------
# 6. MGA UTOS SA PAG-MANAGE NG NGINX
# ------------------------------------------------------------------------------
check_nginx_status() {
    print_title "NGINX SYNTAX & STATUS CHECK"
    if command -v nginx &> /dev/null; then
        print_info "Checking Nginx configuration syntax..."
        nginx -t
        echo ""
        print_info "Checking Nginx service status..."
        systemctl status nginx --no-pager || true
    else
        print_warn "Ang Nginx ay hindi naka-install sa kasalukuyang local machine."
        print_info "Karaniwang sa VPS / Ubuntu server pinapatakbo ang Nginx."
    fi
}

# ------------------------------------------------------------------------------
# 7. INTERACTIVE MENU
# ------------------------------------------------------------------------------
show_menu() {
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${GREEN}    NGINX REVERSE PROXY & SSL (CERTBOT) GABAY         ${NC}"
    echo -e "${BLUE}======================================================${NC}"
    echo " 1) Ano ang Nginx at Paano gumagana ang Reverse Proxy?"
    echo " 2) Paliwanag Kada Linya sa Nginx Config (Alin ang papalitan)"
    echo " 3) Step-by-Step Setup Guide sa Ubuntu / Debian VPS"
    echo " 4) Gabay sa Libreng SSL / HTTPS (Padlock 🔒) gamit ang Certbot"
    echo "------------------------------------------------------"
    echo " 5) Kusang gumawa ng Nginx .conf file para sa project mo"
    echo " 6) I-check ang Nginx status (para sa VPS/Linux)"
    echo " 0) Exit"
    echo -e "${BLUE}======================================================${NC}"
    read -rp "Pumili ng numero [0-6]: " choice

    case "$choice" in
        1) show_overview ;;
        2) show_config_explanation ;;
        3) show_vps_setup_guide ;;
        4) show_ssl_guide ;;
        5) generate_nginx_config ;;
        6) check_nginx_status ;;
        0) exit 0 ;;
        *) print_error "Maling numero. Pumili mula 0 hanggang 6.";;
    esac
}

# ------------------------------------------------------------------------------
# ENTRY POINT
# ------------------------------------------------------------------------------
case "$1" in
    overview)   show_overview ;;
    config)     show_config_explanation ;;
    vps)        show_vps_setup_guide ;;
    ssl)        show_ssl_guide ;;
    generate)   generate_nginx_config ;;
    status)     check_nginx_status ;;
    help|--help|-h)
        echo "Gamit: ./nginx_setup.sh [command]"
        echo ""
        echo "Mga Command:"
        echo "  overview    Tingnan ang diagram kung paano gumagana ang Nginx"
        echo "  config      Paliwanag kada linya sa Nginx configuration"
        echo "  vps         Step-by-step setup guide sa VPS"
        echo "  ssl         Gabay sa pag-install ng libreng SSL gamit ang Certbot"
        echo "  generate    Kusang lumikha ng customized nginx.conf file"
        echo "  status      I-check ang nginx syntax at service status"
        echo "  (walang arg) Bubuksan ang interactive Tagalog menu"
        ;;
    *)
        if [ -n "$1" ]; then
            print_error "Hindi kilalang utos: $1"
            echo "Patakbuhin ang './nginx_setup.sh help' para sa gabay."
            exit 1
        else
            show_menu
        fi
        ;;
esac
