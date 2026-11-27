#!/usr/bin/env bash

# ==============================================================================
# Docker Desktop & WSL2 Installation & Setup Guide for Windows
# ==============================================================================
# Description: Automates and guides the installation, configuration, and
#              verification of WSL2 and Docker Desktop on Windows.
# ==============================================================================

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Helper functions
print_info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warn()    { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
print_step()    { echo -e "\n${BOLD}${BLUE}=== $1 ===${NC}\n"; }

# Detect execution helper for Windows commands in Bash (Git Bash / WSL / MSYS)
run_win_cmd() {
    local cmd="$1"
    if command -v powershell.exe &> /dev/null; then
        powershell.exe -NoProfile -Command "$cmd"
    elif command -v cmd.exe &> /dev/null; then
        cmd.exe /c "$cmd"
    else
        eval "$cmd"
    fi
}

# ------------------------------------------------------------------------------
# 1. System Requirements Check
# ------------------------------------------------------------------------------
check_windows_version() {
    print_step "Step 1: Check Windows Version & Virtualization"

    print_info "Checking Windows Version..."
    if command -v cmd.exe &> /dev/null; then
        cmd.exe /c ver
    elif command -v powershell.exe &> /dev/null; then
        powershell.exe -NoProfile -Command "[System.Environment]::OSVersion.VersionString"
    fi

    echo ""
    print_info "Minimum Requirements:"
    echo "  - Windows 11 64-bit: Home, Pro, Enterprise, or Education (Build 22000+)"
    echo "  - Windows 10 64-bit: Home, Pro (Version 21H2 / Build 19044 or higher)"
    echo "  - Hardware Virtualization enabled in BIOS/UEFI"
    echo "  - Minimum 4 GB RAM"
    echo ""
}

# ------------------------------------------------------------------------------
# 2. WSL2 Setup & Configuration
# ------------------------------------------------------------------------------
setup_wsl2() {
    print_step "Step 2 & 3: Check and Configure WSL2"

    if ! command -v wsl.exe &> /dev/null && ! command -v wsl &> /dev/null; then
        print_warn "wsl command not found. Installing WSL requires Administrator PowerShell:"
        echo "  Run in Admin PowerShell: wsl --install"
        return 1
    fi

    print_info "Current WSL Status:"
    wsl.exe --status 2>/dev/null || wsl --status 2>/dev/null || print_warn "Could not query wsl --status"

    echo ""
    print_info "Installed Linux Distributions:"
    wsl.exe --list --verbose 2>/dev/null || wsl --list --verbose 2>/dev/null || print_warn "No distributions installed yet."

    echo ""
    read -rp "Do you want to update WSL to the latest version? (y/N): " update_confirm
    if [[ "$update_confirm" =~ ^[Yy]$ ]]; then
        print_info "Updating WSL..."
        wsl.exe --update || wsl --update
        print_success "WSL updated successfully."
    fi

    echo ""
    print_info "Setting WSL default version to 2..."
    wsl.exe --set-default-version 2 || wsl --set-default-version 2
    print_success "WSL default version set to 2."
}

# ------------------------------------------------------------------------------
# 3. Docker Desktop Installation
# ------------------------------------------------------------------------------
install_docker_desktop() {
    print_step "Step 4: Install Docker Desktop"

    if command -v docker &> /dev/null; then
        print_warn "Docker is already detected on this system ($(docker --version))."
        read -rp "Do you still want to re-run installation? (y/N): " reinstall
        if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi

    echo "Select an installation method:"
    echo "  1) Install automatically via Windows Package Manager (winget)"
    echo "  2) Open official Docker Desktop download URL in browser"
    echo "  0) Skip"
    read -rp "Choice [1/2/0]: " install_choice

    case "$install_choice" in
        1)
            if command -v winget.exe &> /dev/null || command -v winget &> /dev/null; then
                print_info "Running winget install Docker.DockerDesktop..."
                winget.exe install -e --id Docker.DockerDesktop || winget install -e --id Docker.DockerDesktop
                print_success "Winget installation finished. Restart your computer if prompted."
            else
                print_error "winget is not available on this system."
                print_info "Opening official download page instead..."
                run_win_cmd "Start-Process 'https://www.docker.com/products/docker-desktop/'"
            fi
            ;;
        2)
            print_info "Opening official download URL in your browser..."
            run_win_cmd "Start-Process 'https://www.docker.com/products/docker-desktop/'"
            echo "  URL: https://www.docker.com/products/docker-desktop/"
            ;;
        *)
            print_info "Skipping installation step."
            ;;
    esac
}

# ------------------------------------------------------------------------------
# 4. Docker Desktop Configuration Guide
# ------------------------------------------------------------------------------
show_docker_config_guide() {
    print_step "Step 5: Docker Desktop Configuration"

    echo -e "${YELLOW}Please perform the following inside Docker Desktop Settings:${NC}"
    echo ""
    echo "1. Launch Docker Desktop from the Start Menu."
    echo "2. Open Settings (gear icon in the top right)."
    echo "3. Go to 'General':"
    echo "   [x] Enable 'Use the WSL 2 based engine'"
    echo "4. Go to 'Resources' -> 'WSL Integration':"
    echo "   [x] Enable integration with default WSL distro"
    echo "   [x] Turn on the toggle for your installed Linux distro (e.g., Ubuntu)"
    echo "5. Click 'Apply & restart'."
    echo ""
}

# ------------------------------------------------------------------------------
# 5. Verification & Test
# ------------------------------------------------------------------------------
verify_installation() {
    print_step "Step 6: Verify Docker Installation"

    local ok=true

    print_info "Checking Docker CLI:"
    if command -v docker &> /dev/null; then
        echo "  - $(docker --version)"
    else
        print_error "docker command not found. Make sure Docker Desktop is installed and in PATH."
        ok=false
    fi

    print_info "Checking Docker Compose:"
    if docker compose version &> /dev/null; then
        echo "  - $(docker compose version)"
    else
        print_error "docker compose command not found."
        ok=false
    fi

    print_info "Checking Docker Daemon connection:"
    if docker info &> /dev/null; then
        print_success "Docker daemon is active and responding."
    else
        print_warn "Docker daemon is not running or not responding."
        print_info "Please ensure Docker Desktop is started and finished initializing."
        ok=false
    fi

    if [ "$ok" = true ]; then
        print_success "All Docker components are verified and operational!"
    fi
}

test_docker() {
    print_step "Step 7: Test Docker with 'hello-world'"

    print_info "Running 'docker run hello-world'..."
    if docker run --rm hello-world; then
        echo ""
        print_success "Docker is working correctly!"
    else
        echo ""
        print_error "Docker test failed. Ensure Docker Desktop is running with WSL 2 backend enabled."
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# 6. Interactive Menu
# ------------------------------------------------------------------------------
show_menu() {
    echo -e "${BLUE}==============================================${NC}"
    echo -e "${GREEN}   Docker on Windows Setup & Verification     ${NC}"
    echo -e "${BLUE}==============================================${NC}"
    echo " 1) Check Windows Version & System Specs"
    echo " 2) Setup & Update WSL2"
    echo " 3) Install Docker Desktop (winget / web)"
    echo " 4) View Recommended Docker Desktop Settings"
    echo " 5) Verify Docker Installation"
    echo " 6) Run Test Container (hello-world)"
    echo " 7) Run All Steps In Sequence"
    echo " 0) Exit"
    echo -e "${BLUE}==============================================${NC}"
    read -rp "Select an option [0-7]: " choice

    case "$choice" in
        1) check_windows_version ;;
        2) setup_wsl2 ;;
        3) install_docker_desktop ;;
        4) show_docker_config_guide ;;
        5) verify_installation ;;
        6) test_docker ;;
        7)
            check_windows_version
            setup_wsl2
            install_docker_desktop
            show_docker_config_guide
            verify_installation
            test_docker
            ;;
        0) exit 0 ;;
        *) print_error "Invalid selection.";;
    esac
}

# ------------------------------------------------------------------------------
# Main Entry Point
# ------------------------------------------------------------------------------
case "$1" in
    win|check-win) check_windows_version ;;
    wsl)           setup_wsl2 ;;
    install)       install_docker_desktop ;;
    config)        show_docker_config_guide ;;
    verify)        verify_installation ;;
    test)          test_docker ;;
    all)
        check_windows_version
        setup_wsl2
        install_docker_desktop
        show_docker_config_guide
        verify_installation
        test_docker
        ;;
    help|--help|-h)
        echo "Usage: ./docker_installation_windows.sh [command]"
        echo ""
        echo "Commands:"
        echo "  win|check-win   Verify Windows version & specs"
        echo "  wsl             Check and configure WSL2"
        echo "  install         Install Docker Desktop (winget / web)"
        echo "  config          Show recommended Docker Desktop settings"
        echo "  verify          Verify docker, compose, and daemon status"
        echo "  test            Run hello-world container test"
        echo "  all             Execute complete setup and verification"
        echo "  (no args)       Open interactive menu"
        ;;
    *)
        if [ -n "$1" ]; then
            print_error "Unknown command: $1"
            echo "Run './docker_installation_windows.sh help' for usage."
            exit 1
        else
            show_menu
        fi
        ;;
esac
