# Docker Installation on Windows

## Requirements

- Windows 10/11
- Administrator access
- Internet connection
- Hardware virtualization enabled
- WSL2 support

## Step 1. Check Windows Version

Open PowerShell and execute:

```powershell
winver
```

Verify that your Windows version supports the current Docker Desktop requirements.

## Step 2. Enable WSL2

Open PowerShell as Administrator:

```powershell
wsl --install
```

Restart your computer if prompted.

## Step 3. Update WSL

Open PowerShell:

```powershell
wsl --update
```

Check WSL status:

```powershell
wsl --status
```

Check installed distributions:

```powershell
wsl --list --verbose
```

If an installed Linux distribution is using WSL 1, convert it when appropriate:

```powershell
wsl --set-version Ubuntu 2
```

Set WSL2 as the default:

```powershell
wsl --set-default-version 2
```

## Step 4. Install Docker Desktop

Download Docker Desktop:

https://www.docker.com/products/docker-desktop/

1. Run the installer.
2. Select the WSL2 backend option when available.
3. Complete installation.
4. Restart if prompted.
5. Launch Docker Desktop.

## Step 5. Configure Docker Desktop

Open Docker Desktop.

Go to:

Settings → General

Enable:

- Use the WSL 2 based engine

Go to:

Settings → Resources → WSL Integration

Enable integration for your installed Linux distribution if you intend to use Docker from its terminal.

Apply and restart Docker Desktop if necessary.

## Step 6. Verify Installation

Open PowerShell:

```powershell
docker --version
```

```powershell
docker compose version
```

```powershell
docker info
```

## Step 7. Test Docker

Run:

```powershell
docker run hello-world
```

Expected result:

A message confirming that Docker is working correctly.

## Installation Complete

Docker Desktop is now ready for development projects.

Next: Docker Initial Configuration.