# 🪟 Docker Installation at WSL2 Guide sa Windows 10 / 11

Isang madaling cheat sheet para sa pag-setup ng Docker Desktop at WSL2 sa Windows.

---

## 📌 Talaan ng Nilalaman
1. [Bakit Kailangan ang WSL2?](#1-bakit-kailangan-ang-wsl2)
2. [Mga Kinakailangan (Requirements)](#2-mga-kinakailangan-requirements)
3. [Hakbang 1: I-check ang Windows Version at Virtualization](#hakbang-1-i-check-ang-windows-version-at-virtualization)
4. [Hakbang 2: I-install at I-update ang WSL2](#hakbang-2-i-install-at-i-update-ang-wsl2)
5. [Hakbang 3: I-install ang Docker Desktop](#hakbang-3-i-install-ang-docker-desktop)
6. [Hakbang 4: Mga Setting sa Docker Desktop App](#hakbang-4-mga-setting-sa-docker-desktop-app)
7. [Hakbang 5: Pag-verify at Testing](#hakbang-5-pag-verify-at-testing)
8. [Quick Verification Commands](#quick-verification-commands)

---

## 1. Bakit Kailangan ang WSL2?

Ang Docker ay orihinal na dinisenyo para sa Linux kernel. Sa pamamagitan ng **WSL2 (Windows Subsystem for Linux 2)**, nagpapatakbo ang Windows ng tunay at magaan na Linux kernel sa background. Dito kumukuha ng bilis ang Docker Desktop sa Windows.

---

## 2. Mga Kinakailangan (Requirements)

- **OS:** Windows 10 64-bit (Version 21H2 pataas) o Windows 11 (64-bit).
- **Virtualization:** Naka-enable ang Hardware Virtualization sa BIOS/UEFI.
- **RAM:** Minimum na 4 GB (Inirerekomenda ang 8 GB pataas).

---

## Hakbang 1: I-check ang Windows Version at Virtualization

### 1. I-check ang Windows Version:
Buksan ang PowerShell o Command Prompt:
```powershell
winver
```

### 2. I-check ang CPU Virtualization:
1. Pindutin ang `Ctrl + Shift + Esc` para buksan ang **Task Manager**.
2. Pumunta sa tab na **Performance** ➔ **CPU**.
3. Tingnan sa kanang ibaba kung nakasulat ay:
   ```text
   Virtualization: Enabled
   ```
   > ⚠️ **Kung "Disabled":** Kailangan itong i-enable sa BIOS/UEFI ng iyong PC/laptop (hanapin ang *Intel Virtualization Technology / Intel VT-x* o *AMD-V / SVM Mode*).

---

## Hakbang 2: I-install at I-update ang WSL2

Buksan ang **PowerShell bilang Administrator** (*Right-click sa Start menu ➔ Terminal (Admin) o PowerShell (Admin)*):

### 1. I-install ang WSL:
```powershell
wsl --install
```
*(Kung hiningan ka ng restart, i-restart ang iyong computer bago magpatuloy).*

### 2. I-update ang WSL sa pinakabagong bersyon:
```powershell
wsl --update
```

### 3. I-set ang WSL Version 2 bilang Default:
```powershell
wsl --set-default-version 2
```

### 4. I-check ang kasalukuyang status ng WSL:
```powershell
wsl --status
```

---

## Hakbang 3: I-install ang Docker Desktop

Pumili ng isa sa dalawang paraan:

### Paraan A: Gamit ang Official Installer (Inirerekomenda)
1. I-download ang installer mula sa opisyal na website:  
   👉 [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)
2. Patakbuhin ang `Docker Desktop Installer.exe`.
3. Sa installation prompt, siguraduhing **may tsek** ang:
   - `[x] Use WSL 2 instead of Hyper-V (recommended)`
4. Pindutin ang **Ok**, at hintaying matapos.
5. I-restart ang computer kung hiningi ng installer.

### Paraan B: Gamit ang Windows Package Manager (Winget)
Sa PowerShell:
```powershell
winget install -e --id Docker.DockerDesktop
```

---

## Hakbang 4: Mga Setting sa Docker Desktop App

Buksan ang **Docker Desktop** app mula sa iyong Start Menu:

1. I-click ang **GEAR ICON ⚙️ (Settings)** sa kanang itaas.
2. Pumunta sa **General**:
   - `[x] Use the WSL 2 based engine` *(dapat may tsek)*.
3. Pumunta sa **Resources** ➔ **WSL Integration**:
   - `[x] Enable integration with my default WSL distro` *(may tsek)*.
   - Kung may naka-install kang Ubuntu distro, i-ON ang switch sa tabi nito.
4. I-click ang **Apply & restart** sa kanang ibaba.

---

## Hakbang 5: Pag-verify at Testing

Buksan ang iyong terminal (PowerShell, Git Bash, o Command Prompt):

### 1. Tingnan kung gumagana ang Docker commands:
```bash
docker --version
docker compose version
```

### 2. Patakbuhin ang opisyal na test container:
```bash
docker run --rm hello-world
```

**Inaasahang Resulta:**  
May lalabas na mensaheng:
```text
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

🎉 **Handa na ang iyong computer para sa mga Docker projects!**

---

## Quick Verification Commands

```powershell
# Tingnan ang Docker engine status
docker info

# Tingnan ang listahan ng tumatakbong containers
docker ps

# Tingnan ang lahat ng containers (pati mga nakahinto)
docker ps -a
```
