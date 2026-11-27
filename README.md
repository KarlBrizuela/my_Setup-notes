# 🚀 My Setup & Deployment Notes

Isang personal na cheat sheet at dokumentasyon para sa Docker, CI/CD (GitHub Actions), at Nginx Reverse Proxy na may kasamang linya-por-linyang gabay sa Tagalog.

---

## 📚 Talaan ng mga Gabay (Cheat Sheets)

| Folder | Dokumentasyon (.md) | Script (.sh) | Paglalarawan |
|---|---|---|---|
| **🐳 Docker Setup** | [docker_setup_project.md](<docker setup/docker_setup_project.md>) | [docker_setup_project.sh](<docker setup/docker_setup_project.sh>) | Setup templates para sa Next.js at Laravel + MySQL, may paliwanag kada linya. |
| **🪟 Docker on Windows** | [docker_installation_windows.md](<docker setup/docker_installation_windows.md>) | [docker_installation_windows.sh](<docker setup/docker_installation_windows.sh>) | Step-by-step pag-install ng WSL2 at Docker Desktop sa Windows 10/11. |
| **🚀 CI/CD Pipeline** | [CI_CD_setup.md](<CI/CD setup/CI_CD_setup.md>) | [CI/CD_setup.sh](<CI/CD setup/CI/CD_setup.sh>) | GitHub Actions auto-test, Docker build, at auto-deploy sa VPS via SSH. |
| **🌐 Nginx & SSL** | [nginx_setup.md](<nginx setup/nginx_setup.md>) | [nginx_setup.sh](<nginx setup/nginx_setup.sh>) | Nginx Reverse Proxy config para sa Docker containers at libreng Certbot SSL. |

---

## ⚡ Paano Gamitin ang Repository na Ito

1. **Sa Browser (GitHub):**  
   Buksan ang kahit anong `.md` link sa itaas para mabasa ang kumpletong cheat sheet, kopyahin ang mga sample code blocks gamit ang GitHub copy button, at makita kung aling linya ang dapat mong palitan para sa iyong project.

2. **Sa Terminal (Optional Automation):**  
   Kung gusto mong awtomatikong mag-generate ng files o mag-scaffold, may kasama ring executable `.sh` scripts na may interactive menu ang bawat folder:
   ```bash
   # Docker scaffold
   bash "docker setup/docker_setup_project.sh"

   # CI/CD generator
   bash "CI/CD setup/CI/CD_setup.sh"

   # Nginx config generator
   bash "nginx setup/nginx_setup.sh"
   ```
