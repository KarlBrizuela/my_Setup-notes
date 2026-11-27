# Nginx Reverse Proxy & Libreng SSL (Certbot) Guide

Cheat sheet para sa pag-setup ng Nginx bilang Reverse Proxy para sa Docker containers at paglalagay ng libreng HTTPS / SSL certificate gamit ang Let's Encrypt (Certbot).

---

## Talaan ng Nilalaman
1. [Ano ang Nginx at Bakit Ito Kailangan](#1-ano-ang-nginx-at-bakit-ito-kailangan)
2. [Paano Gumagana ang Reverse Proxy](#2-paano-gumagana-ang-reverse-proxy)
3. [Nginx Configuration File (/etc/nginx/sites-available/myproject.conf)](#3-nginx-configuration-file)
4. [Step-by-Step Setup sa Ubuntu / Debian VPS](#4-step-by-step-setup-sa-ubuntu--debian-vps)
5. [Libreng SSL / HTTPS gamit ang Certbot](#5-libreng-ssl--https-gamit-ang-certbot)
6. [Mga Kapaki-pakinabang na Nginx Commands (Cheat Sheet)](#6-mga-kapaki-pakinabang-na-nginx-commands-cheat-sheet)
7. [Mga Karaniwang Problema at Solusyon (Troubleshooting)](#7-mga-karaniwang-problema-at-solusyon-troubleshooting)

---

## 1. Ano ang Nginx at Bakit Ito Kailangan

Sa live production environment:
- **Hindi binubuksan ang internal Docker application ports (tulad ng 3000 o 8000) nang direkta sa publiko.**
- Ang **Nginx** ay nagsisilbing Reverse Proxy sa standard ports 80 (HTTP) at 443 (HTTPS).
- Si Nginx ang sumasalo ng mga incoming web requests at nagpapasa nito papunta sa loob ng Docker container (`proxy_pass http://127.0.0.1:3000`).

### Pangunahing Gamit ng Nginx:
1. **Custom Domain:** Paggamit ng domain name (hal. `myproject.com`) sa halip na may kasamang port tulad ng `http://123.45.67.89:3000`.
2. **SSL / HTTPS Encryption:** Awtomatikong nag-i-install ng libreng SSL certificates mula sa Let's Encrypt para sa secure HTTPS connections.
3. **Maramihang Websites sa Iisang VPS:** Pwedeng magpatakbo ng higit sa isang application sa parehong server gamit ang subdomains (hal. `app.domain.com` papunta sa port 3000, at `api.domain.com` papunta sa port 8000).

---

## 2. Paano Gumagana ang Reverse Proxy

```text
[User sa Browser]
       │
       │ Request: https://myproject.com
       ▼
[Nginx sa Port 80 / 443 (May SSL)]
       │
       │ Nagpapasa ng request (proxy_pass)
       ▼
[Docker Container sa VPS (Port 3000 o 8000)]
       │
       │ Pinoproseso ang application logic
       ▼
[Ibabalik ang response pabalik sa User]
```

---

## 3. Nginx Configuration File

Gumawa ng file sa iyong VPS sa path na: `/etc/nginx/sites-available/myproject.conf`

```nginx
server {
    # [WAG GALAWIN]: Nakikinig sa standard HTTP port 80 (IPv4 at IPv6)
    listen 80;
    listen [::]:80;

    # [PAPALITAN MO]: Ilagay ang biniling domain name o subdomain.
    #                 Kung wala pang domain, ilagay ang Public IP ng VPS mo.
    server_name myproject.com www.myproject.com;

    # [PAPALITAN MO]: Maximum upload file size para sa forms at media uploads.
    client_max_body_size 50M;

    location / {
        # [PAPALITAN MO]: Palitan ang '3000' ng port ng iyong Docker container.
        #                 - Next.js: karaniwan ay 3000
        #                 - Laravel: karaniwan ay 8000
        proxy_pass http://127.0.0.1:3000;

        # [WAG GALAWIN]: Standard proxy protocol at WebSocket connection headers
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';

        # [PALIWANAG]: Ipinapasa ang original domain name papunta sa container
        proxy_set_header Host $host;

        # [PALIWANAG]: Ipinapasa ang tunay na IP address ng user papasok sa application
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_cache_bypass $http_upgrade;

        # [PALIWANAG]: Timeout limits para sa mabibigat na requests
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

---

## 4. Step-by-Step Setup sa Ubuntu / Debian VPS

Patakbuhin ang sumusunod na commands sa terminal ng VPS:

### Hakbang 1: I-install ang Nginx
```bash
sudo apt update
sudo apt install nginx -y
```

### Hakbang 2: Simulan ang Nginx service
```bash
sudo systemctl start nginx
sudo systemctl enable nginx
```

### Hakbang 3: Gumawa ng bagong site configuration file
```bash
sudo nano /etc/nginx/sites-available/myproject.conf
```
*(I-paste ang template mula sa Seksyon 3, i-update ang `server_name` at `proxy_pass` port, at i-save gamit ang `Ctrl + O`, `Enter`, at `Ctrl + X`).*

### Hakbang 4: I-activate ang configuration gamit ang symlink
```bash
sudo ln -s /etc/nginx/sites-available/myproject.conf /etc/nginx/sites-enabled/
```

### Hakbang 5: I-verify ang configuration syntax
```bash
sudo nginx -t
```
> Dapat lumabas ang mensaheng:  
> `nginx: configuration file /etc/nginx/nginx.conf test is successful`

### Hakbang 6: I-reload ang Nginx
```bash
sudo systemctl reload nginx
```

---

## 5. Libreng SSL / HTTPS gamit ang Certbot

Kapag may sarili ka nang domain name na nakaturo sa Public IP ng VPS mo (A Record sa DNS provider):

### Hakbang 1: I-install ang Certbot at Nginx package
```bash
sudo apt update
sudo apt install certbot python3-certbot-nginx -y
```

### Hakbang 2: Humiling ng SSL Certificate
```bash
sudo certbot --nginx -d myproject.com -d www.myproject.com
```

### Mga Prompt ng Certbot:
1. **Email Address:** Ilagay ang iyong active email para sa security notifications.
2. **Terms of Service:** I-type ang `Y` at pindutin ang `Enter`.
3. **Share Email:** Pwedeng `N`.
4. **Redirect HTTP to HTTPS:** Piliin ang opsyon na may redirect (inirerekomenda).

Awtomatikong ia-update ng Certbot ang iyong Nginx configuration at magiging aktibo na ang HTTPS certificate.

### Auto-Renewal ng SSL:
Ang Let's Encrypt certificates ay valid sa loob ng 90 days, ngunit awtomatiko itong nire-renew ng Certbot bago mag-expire. Para i-test ang renewal scheduler:
```bash
sudo certbot renew --dry-run
```

---

## 6. Mga Kapaki-pakinabang na Nginx Commands (Cheat Sheet)

| Command | Deskripsyon |
|---|---|
| `sudo nginx -t` | I-test ang syntax ng configuration files bago mag-reload. |
| `sudo systemctl reload nginx` | I-apply ang bagong configuration nang walang server downtime. |
| `sudo systemctl restart nginx` | I-restart ang buong Nginx service. |
| `sudo systemctl status nginx` | Tingnan kung active at tumatakbo ang Nginx. |
| `sudo tail -f /var/log/nginx/error.log` | Tingnan ang live error logs ng Nginx. |
| `sudo tail -f /var/log/nginx/access.log` | Tingnan ang incoming access logs ng mga bisita. |

---

## 7. Mga Karaniwang Problema at Solusyon (Troubleshooting)

### Problema 1: "502 Bad Gateway"
- **Dahilan:** Hindi ma-reach ni Nginx ang Docker container sa port na tinukoy.
- **Solusyon:** 
  1. I-verify kung tumatakbo ang container: `docker compose ps`.
  2. Siguraduhing tugma ang port sa `proxy_pass` sa port na naka-bind sa `compose.yaml` (hal. `3000`).

### Problema 2: "nginx: [emerg] a duplicate default server"
- **Dahilan:** May conflict sa default configuration ng Nginx sa port 80.
- **Solusyon:** Tanggalin ang default symlink:
  ```bash
  sudo rm /etc/nginx/sites-enabled/default
  sudo nginx -t && sudo systemctl reload nginx
  ```

### Problema 3: "413 Request Entity Too Large"
- **Dahilan:** Lumagpas ang in-upload na file sa default limit ng Nginx (1 MB).
- **Solusyon:** Taasan ang limit sa pamamagitan ng pagdagdag ng `client_max_body_size`:
  ```nginx
  client_max_body_size 100M;
  ```
