# 🌐 Nginx Reverse Proxy & Libreng SSL (Certbot) Guide

Isang praktikal na cheat sheet para sa pag-setup ng Nginx bilang **Reverse Proxy** sa iyong Docker containers at paglalagay ng libreng **HTTPS / SSL Certificate (Padlock 🔒)** gamit ang Let's Encrypt (Certbot).

---

## 📌 Talaan ng Nilalaman
1. [Ano ang Nginx at Bakit Ito Kailangan?](#1-ano-ang-nginx-at-bakit-ito-kailangan)
2. [Paano Gumagana ang Reverse Proxy? (Diagram)](#2-paano-gumagana-ang-reverse-proxy-diagram)
3. [Nginx Configuration File (/etc/nginx/sites-available/myproject.conf)](#3-nginx-configuration-file)
4. [Step-by-Step Setup sa Ubuntu / Debian VPS](#4-step-by-step-setup-sa-ubuntu--debian-vps)
5. [Libreng SSL / HTTPS (Padlock 🔒) gamit ang Certbot](#5-libreng-ssl--https-padlock--gamit-ang-certbot)
6. [Mga Kapaki-pakinabang na Nginx Commands (Cheat Sheet)](#6-mga-kapaki-pakinabang-na-nginx-commands-cheat-sheet)
7. [Mga Karaniwang Problema at Solusyon (Troubleshooting)](#7-mga-karaniwang-problema-at-solusyon-troubleshooting)

---

## 1. Ano ang Nginx at Bakit Ito Kailangan?

Sa live production server:
- **Hindi natin basta binubuksan ang internal Docker port (hal. 3000 o 8000) sa publiko.**
- Si **Nginx** ang nagsisilbing "Traffic Enforcer / Guard" (Reverse Proxy) sa port 80 (HTTP) at port 443 (HTTPS).
- Si Nginx ang sumasalo ng mga request mula sa internet at nagpapasa nito papunta sa loob ng Docker container mo (`proxy_pass http://127.0.0.1:3000`).

### Mga Benepisyo ng Nginx:
1. **Custom Domain:** Pwedeng `myproject.com` sa halip na may pangit na port tulad ng `http://123.45.67.89:3000`.
2. **Libreng SSL / HTTPS:** Kusa nitong ikinakabit ang Let's Encrypt SSL para may padlock 🔒 sa browser.
3. **Maramihang Websites sa Iisang VPS:** Pwedeng magpatakbo ng maraming apps sa iisang server (hal. `app.domain.com` sa Port 3000, `api.domain.com` sa Port 8000).

---

## 2. Paano Gumagana ang Reverse Proxy? (Diagram)

```text
[User sa Internet (Browser)]
       │
       │ Nag-type ng: https://myproject.com
       ▼
[Nginx sa Port 80 / 443 (May SSL Padlock 🔒)]
       │
       │ Sinasala at pinapasa ang request (proxy_pass)
       ▼
[Docker Container sa loob ng VPS (Port 3000 o 8000)]
       │
       │ Pinoproseso ang Next.js o Laravel code
       ▼
[Ibabalik ang response papunta sa User sa Browser] 🎉
```

---

## 3. Nginx Configuration File

Gumawa ng file sa iyong VPS sa path na: `/etc/nginx/sites-available/myproject.conf`

```nginx
server {
    # 🔒 [WAG GALAWIN]: Nakikinig sa standard HTTP port 80 (IPv4 at IPv6)
    listen 80;
    listen [::]:80;

    # ✏️ [PAPALITAN MO]: Ilagay dito ang binili mong domain name o subdomain.
    #                    Kung wala pang domain, ilagay ang Public IP ng VPS mo.
    server_name myproject.com www.myproject.com;

    # ✏️ [PAPALITAN MO]: Maximum upload file size ng mga forms at images sa website mo.
    client_max_body_size 50M;

    location / {
        # ✏️ [PAPALITAN MO]: ANG PINAKAMAHALAGANG LINYA!
        #                    Palitan ang '3000' ng port kung saan tumatakbo ang Docker container mo.
        #                    - Next.js: karaniwan ay 3000
        #                    - Laravel: karaniwan ay 8000
        proxy_pass http://127.0.0.1:3000;

        # 🔒 [WAG GALAWIN]: Standard proxy settings para sa mabilis na koneksyon at WebSockets
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';

        # 👉 [PARA SAAN]: Ipinapasa ang totoong domain name sa loob ng container
        proxy_set_header Host $host;

        # 👉 [PARA SAAN]: Ipinapasa ang totoong IP address ng bumibisita sa website mo
        #                 (kung wala ito, aakalain ng app mo na 127.0.0.1 ang IP ng lahat ng bisita!)
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_cache_bypass $http_upgrade;

        # 👉 [PARA SAAN]: Timeout settings para hindi mag-error ang mabibigat na API requests
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

---

## 4. Step-by-Step Setup sa Ubuntu / Debian VPS

Kopyahin at patakbuhin ang mga sumusunod na commands sa terminal ng iyong VPS:

### Hakbang 1: I-install ang Nginx
```bash
sudo apt update
sudo apt install nginx -y
```

### Hakbang 2: Siguraduhing tumatakbo ang Nginx
```bash
sudo systemctl start nginx
sudo systemctl enable nginx
```

### Hakbang 3: Gumawa ng bagong config file para sa project mo
```bash
sudo nano /etc/nginx/sites-available/myproject.conf
```
*(I-paste ang template mula sa Seksyon 3, palitan ang `server_name` at `proxy_pass` port, tapos pindutin ang `Ctrl + O`, `Enter`, at `Ctrl + X` para i-save).*

### Hakbang 4: I-enable ang iyong site gamit ang Symlink
```bash
sudo ln -s /etc/nginx/sites-available/myproject.conf /etc/nginx/sites-enabled/
```

### Hakbang 5: I-test kung walang error sa syntax ng Nginx
```bash
sudo nginx -t
```
> Dapat lumabas ang mensaheng:  
> `nginx: configuration file /etc/nginx/nginx.conf test is successful`

### Hakbang 6: I-reload ang Nginx para magkabisa
```bash
sudo systemctl reload nginx
```

---

## 5. Libreng SSL / HTTPS (Padlock 🔒) gamit ang Certbot

Kapag may binili ka nang domain name at nakaturo na ang **A Record** ng DNS sa IP address ng VPS mo:

### Hakbang 1: I-install ang Certbot at Nginx plugin
```bash
sudo apt update
sudo apt install certbot python3-certbot-nginx -y
```

### Hakbang 2: Humingi ng SSL Certificate para sa iyong domain
```bash
sudo certbot --nginx -d myproject.com -d www.myproject.com
```

### Mga itatanong ng Certbot:
1. **Email Address:** Ilagay ang email mo (para sa security updates at notices).
2. **Terms of Service:** I-type ang `Y` at pindutin ang `Enter`.
3. **Share Email:** Pwedeng `N`.
4. **Redirect HTTP to HTTPS:** Piliin ang `2` (Redirect - Recommended para kahit mag-type ng http://, kusa itong magiging https://).

🎉 **Tapos na! Kusa nang papalitan ng Certbot ang Nginx config mo at magkakaroon na ng Padlock 🔒 ang iyong website!**

### Auto-Renewal ng SSL:
Libre ang Let's Encrypt certificate sa loob ng 90 days, ngunit **kusang nagre-renew** ang Certbot bago pa mag-expire. Para masubukan kung gagana ang auto-renewal:
```bash
sudo certbot renew --dry-run
```

---

## 6. Mga Kapaki-pakinabang na Nginx Commands (Cheat Sheet)

| Command | Kailan gagamitin? |
|---|---|
| `sudo nginx -t` | **I-test ang syntax** ng config bago mag-restart (para maiwasang masira ang server). |
| `sudo systemctl reload nginx` | **I-apply ang bagong config** nang hindi pinapatay ang mga kasalukuyang koneksyon. |
| `sudo systemctl restart nginx` | **I-restart** ang buong Nginx service. |
| `sudo systemctl status nginx` | **Tingnan ang status** (kung active/running). |
| `sudo tail -f /var/log/nginx/error.log` | **Tingnan ang live error logs** kapag may problema sa routing. |
| `sudo tail -f /var/log/nginx/access.log` | **Tingnan ang live traffic** ng mga pumapasok na bisita sa site mo. |

---

## 7. Mga Karaniwang Problema at Solusyon (Troubleshooting)

### ❓ Problema 1: "502 Bad Gateway"
- **Dahilan:** Hindi ma-reach ni Nginx ang Docker container mo.
- **Solusyon:** 
  1. Siguraduhing tumatakbo ang container sa VPS: `docker compose ps`.
  2. Siguraduhing tumutugma ang port sa `proxy_pass` sa port na nakalagay sa `compose.yaml` (hal. `3000`).

### ❓ Problema 2: "nginx: [emerg] a duplicate default server"
- **Dahilan:** Nag-aagawan ang default config at ang bago mong config sa port 80.
- **Solusyon:** Tanggalin ang default file:
  ```bash
  sudo rm /etc/nginx/sites-enabled/default
  sudo nginx -t && sudo systemctl reload nginx
  ```

### ❓ Problema 3: "413 Request Entity Too Large"
- **Dahilan:** Lumagpas sa file size limit ang in-upload na image o file ng user.
- **Solusyon:** Taasan ang `client_max_body_size` sa iyong config file:
  ```nginx
  client_max_body_size 100M;
  ```
