# My Setup & Deployment Notes

Personal na cheat sheet at gabay para sa Docker, CI/CD gamit ang GitHub Actions, at Nginx Reverse Proxy. May kasamang paliwanag sa bawat linya ng configuration.

---

## Talaan ng Nilalaman

| Kategorya | Dokumentasyon (.md) | Automation Script (.sh) | Deskripsyon |
|---|---|---|---|
| **Docker Project Setup** | [docker_setup_project.md](<docker setup/docker_setup_project.md>) | [docker_setup_project.sh](<docker setup/docker_setup_project.sh>) | Setup templates para sa Next.js at Laravel + MySQL na may paliwanag kada linya. |
| **Docker sa Windows** | [docker_installation_windows.md](<docker setup/docker_installation_windows.md>) | [docker_installation_windows.sh](<docker setup/docker_installation_windows.sh>) | Gabay sa pag-install ng WSL2 at Docker Desktop sa Windows 10/11. |
| **CI/CD Pipeline** | [CI_CD_setup.md](<CI/CD setup/CI_CD_setup.md>) | [CI/CD_setup.sh](<CI/CD setup/CI/CD_setup.sh>) | GitHub Actions auto-test, Docker build, at auto-deploy sa VPS gamit ang SSH. |
| **Nginx at SSL** | [nginx_setup.md](<nginx setup/nginx_setup.md>) | [nginx_setup.sh](<nginx setup/nginx_setup.sh>) | Nginx Reverse Proxy config para sa Docker containers at libreng Certbot SSL. |

---

## Paano Gamitin ang Repository

1. **Pagsusuri sa GitHub:**  
   I-click ang alinman sa mga `.md` link sa itaas para mabasa ang documentation, kopyahin ang mga sample configuration, at makita kung aling linya ang dapat palitan para sa project mo.

2. **Automation Scripts (Opsyonal):**  
   Kung nais mong mag-generate ng files o magpatakbo ng commands nang mabilis sa terminal, may kasamang `.sh` script ang bawat folder:
   ```bash
   # Docker scaffold
   bash "docker setup/docker_setup_project.sh"

   # CI/CD generator
   bash "CI/CD setup/CI/CD_setup.sh"

   # Nginx config generator
   bash "nginx setup/nginx_setup.sh"
   ```
