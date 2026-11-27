# Docker Installation at WSL2 Guide sa Windows 10 / 11

Cheat sheet para sa pag-install at pag-configure ng Docker Desktop at WSL2 sa Windows.

---

## Talaan ng Nilalaman
1. [Bakit Kailangan ang WSL2](#1-bakit-kailangan-ang-wsl2)
2. [Mga Kinakailangan (System Requirements)](#2-mga-kinakailangan-system-requirements)
3. [Hakbang 1: I-check ang Windows Version at Virtualization](#hakbang-1-i-check-ang-windows-version-at-virtualization)
4. [Hakbang 2: I-install at I-update ang WSL2](#hakbang-2-i-install-at-i-update-ang-wsl2)
5. [Hakbang 3: I-install ang Docker Desktop](#hakbang-3-i-install-ang-docker-desktop)
6. [Hakbang 4: Configuration sa Loob ng Docker Desktop App](#hakbang-4-configuration-sa-loob-ng-docker-desktop-app)
7. [Hakbang 5: Pag-verify at Testing](#hakbang-5-pag-verify-at-testing)
8. [Quick Verification Commands](#quick-verification-commands)

---

## 1. Bakit Kailangan ang WSL2

Ang Docker engine ay katutubong tumatakbo sa Linux kernel. Sa pamamagitan ng **WSL2 (Windows Subsystem for Linux 2)**, nagpapatakbo ang Windows ng magaan at tunay na Linux kernel sa background. Dito kumukuha ng performance ang Docker Desktop sa Windows.

---

## 2. Mga Kinakailangan (System Requirements)

- **OS:** Windows 10 64-bit (Version 21H2 o mas mataas) o Windows 11 (64-bit).
- **Virtualization:** Naka-enable ang Hardware Virtualization sa BIOS/UEFI.
- **Memory:** Minimum na 4 GB RAM (8 GB pataas ang inirerekomenda).

---

## Hakbang 1: I-check ang Windows Version at Virtualization

### 1. I-check ang Windows Version
Sa PowerShell o Command Prompt:
```powershell
winver
```

### 2. I-check ang CPU Virtualization
1. Pindutin ang `Ctrl + Shift + Esc` para buksan ang **Task Manager**.
2. Pumunta sa tab na **Performance** > **CPU**.
3. Tingnan sa ibabang kanang bahagi kung nakalagay ay:
   ```text
   Virtualization: Enabled
   ```
   > **Paalala kung "Disabled":** Kailangan itong i-enable sa BIOS/UEFI ng iyong motherboard (hanapin ang setting na *Intel Virtualization Technology / Intel VT-x* o *AMD-V / SVM Mode*).

---

## Hakbang 2: I-install at I-update ang WSL2

Buksan ang **PowerShell bilang Administrator** (*Right-click sa Start menu > Terminal (Admin) o PowerShell (Admin)*):

### 1. I-install ang WSL
```powershell
wsl --install
```
*(Kung humingi ng restart ang system, i-restart ang computer bago magpatuloy).*

### 2. I-update ang WSL sa pinakabagong release
```powershell
wsl --update
```

### 3. I-set ang WSL Version 2 bilang Default
```powershell
wsl --set-default-version 2
```

### 4. Tingnan ang kasalukuyang status ng WSL
```powershell
wsl --status
```

---

## Hakbang 3: I-install ang Docker Desktop

Pumili sa dalawang opsyon:

### Opsyon A: Gamit ang Official Installer (Inirerekomenda)
1. I-download ang installer mula sa opisyal na website:  
   https://www.docker.com/products/docker-desktop/
2. Patakbuhin ang `Docker Desktop Installer.exe`.
3. Sa dialog box, tiyaking naka-check ang:
   - `[x] Use WSL 2 instead of Hyper-V (recommended)`
4. Pindutin ang **Ok**, at hintaying matapos ang installation.
5. I-restart ang computer kung kinakailangan.

### Opsyon B: Gamit ang Windows Package Manager (Winget)
Sa PowerShell:
```powershell
winget install -e --id Docker.DockerDesktop
```

---

## Hakbang 4: Configuration sa Loob ng Docker Desktop App

Buksan ang **Docker Desktop** mula sa Start Menu:

1. I-click ang **Settings (Gear Icon)** sa kanang itaas.
2. Sa kaliwang menu, pumunta sa **General**:
   - `[x] Use the WSL 2 based engine` *(dapat naka-check)*.
3. Pumunta sa **Resources** > **WSL Integration**:
   - `[x] Enable integration with my default WSL distro` *(naka-check)*.
   - Kung may naka-install kang Linux distribution (tulad ng Ubuntu), i-toggle ang switch sa tabi nito.
4. I-click ang **Apply & restart**.

---

## Hakbang 5: Pag-verify at Testing

Buksan ang terminal (PowerShell, Git Bash, o Command Prompt):

### 1. Tingnan kung gumagana ang Docker commands
```bash
docker --version
docker compose version
```

### 2. Patakbuhin ang opisyal na test container
```bash
docker run --rm hello-world
```

**Inaasahang Output:**  
Lalabas ang sumusunod na mensahe:
```text
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

Tapos na ang installation at handa na ang Docker environment sa iyong Windows machine.

---

## Quick Verification Commands

```powershell
# Tingnan ang buong configuration at status ng Docker engine
docker info

# Listahan ng tumatakbong containers
docker ps

# Listahan ng lahat ng containers (kasama ang mga nakahinto)
docker ps -a
```
