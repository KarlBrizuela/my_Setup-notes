#!/usr/bin/env bash

# ==============================================================================
# GABAY SA PAG-INSTALL NG DOCKER AT WSL2 SA WINDOWS 10 / 11
# ==============================================================================
# Bakit kailangan ng WSL2 para sa Docker sa Windows?
#  - Ang Docker ay katutubong tumatakbo sa Linux kernel.
#  - Gamit ang WSL2 (Windows Subsystem for Linux 2), nagpapatakbo ang Windows
#    ng tunay na Linux kernel sa background.
#  - Dito kumukuha ng bilis ang Docker Desktop sa Windows.
# ==============================================================================

set -e

# Mga Kulay para sa terminal
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
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# ------------------------------------------------------------------------------
# 1. HAKBANG 1: CHECK WINDOWS VERSION & HARDWARE VIRTUALIZATION
# ------------------------------------------------------------------------------
check_windows() {
    print_title "HAKBANG 1: CHECK ANG WINDOWS VERSION AT HARDWARE VIRTUALIZATION"

    print_info "Kasalukuyang Bersyon ng Windows:"
    if command -v cmd.exe &> /dev/null; then
        cmd.exe /c ver
    elif command -v powershell.exe &> /dev/null; then
        powershell.exe -NoProfile -Command "[System.Environment]::OSVersion.VersionString"
    fi

    echo ""
    print_info "MGA KINAKAILANGAN (REQUIREMENTS):"
    echo "  1. Windows 11 (64-bit) o Windows 10 (64-bit, Version 21H2 pataas)"
    echo "  2. Hardware Virtualization Enabled sa BIOS/UEFI:"
    echo "     - Buksan ang Task Manager (Ctrl + Shift + Esc)"
    echo "     - Pumunta sa tab na 'Performance' -> 'CPU'"
    echo "     - Tingnan sa bandang ibaba kung 'Virtualization: Enabled'"
    echo "     - Kung 'Disabled', kailangan itong i-enable sa BIOS (Intel VT-x o AMD-V)."
    echo ""
}

# ------------------------------------------------------------------------------
# 2. HAKBANG 2 & 3: PAG-SETUP AT PAG-UPDATE NG WSL2
# ------------------------------------------------------------------------------
setup_wsl2() {
    print_title "HAKBANG 2 & 3: PAG-SETUP AT PAG-UPDATE NG WSL2"

    if ! command -v wsl.exe &> /dev/null && ! command -v wsl &> /dev/null; then
        print_error "Hindi mahanap ang 'wsl' command."
        print_info "Buksan ang PowerShell bilang Administrator at patakbuhin:"
        echo "  wsl --install"
        echo "(I-restart ang computer pagkatapos)."
        return 1
    fi

    print_info "Kasalukuyang Status ng WSL:"
    wsl.exe --status 2>/dev/null || wsl --status 2>/dev/null || print_warn "Hindi ma-query ang status."

    echo ""
    print_info "Naka-install na mga Linux Distribution:"
    wsl.exe --list --verbose 2>/dev/null || wsl --list --verbose 2>/dev/null || print_info "Wala pang distribution."

    echo ""
    read -rp "Gusto mo bang i-update ang WSL sa pinakabagong bersyon? (y/N): " update_confirm
    if [[ "$update_confirm" =~ ^[Yy]$ ]]; then
        print_info "Ina-update ang WSL..."
        wsl.exe --update || wsl --update
        print_success "Na-update na ang WSL."
    fi

    echo ""
    print_info "Siniset ang default version ng WSL sa Bersyon 2..."
    wsl.exe --set-default-version 2 || wsl --set-default-version 2
    print_success "WSL2 na ang default version."
}

# ------------------------------------------------------------------------------
# 3. HAKBANG 4: PAG-INSTALL NG DOCKER DESKTOP
# ------------------------------------------------------------------------------
install_docker() {
    print_title "HAKBANG 4: PAG-INSTALL NG DOCKER DESKTOP"

    if command -v docker &> /dev/null; then
        print_warn "May Docker na sa computer mo ($(docker --version))."
        read -rp "Gusto mo pa bang ituloy ang installer? (y/N): " reinstall
        if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi

    echo "Pumili ng paraan ng pag-install:"
    echo "  1) Awtomatikong i-install gamit ang winget (Windows Package Manager)"
    echo "  2) Buksan ang opisyal na download website sa browser"
    echo "  0) Lumaktaw (Skip)"
    read -rp "Piliin [1/2/0]: " method

    case "$method" in
        1)
            if command -v winget.exe &> /dev/null || command -v winget &> /dev/null; then
                print_info "Pinapatakbo ang: winget install Docker.DockerDesktop..."
                winget.exe install -e --id Docker.DockerDesktop || winget install -e --id Docker.DockerDesktop
                print_success "Tapos na ang pag-install. I-restart ang PC kung kinakailangan."
            else
                print_error "Walang winget. Bubuksan ang download website..."
                powershell.exe -Command "Start-Process 'https://www.docker.com/products/docker-desktop/'"
            fi
            ;;
        2)
            print_info "Binubuksan ang Docker Desktop download page..."
            powershell.exe -Command "Start-Process 'https://www.docker.com/products/docker-desktop/'"
            ;;
        *)
            print_info "Nilaktawan ang pag-install."
            ;;
    esac
}

# ------------------------------------------------------------------------------
# 4. HAKBANG 5: GABAY SA SETTINGS NG DOCKER DESKTOP
# ------------------------------------------------------------------------------
explain_settings() {
    print_title "HAKBANG 5: MGA DAPAT I-SET SA LOOB NG DOCKER DESKTOP APP"
    cat << 'EOF'
Pagkatapos ma-install ang Docker Desktop, buksan ito at gawin ang sumusunod:

1. I-click ang Settings (Gear Icon) sa bandang kanang itaas.
2. Sa kaliwang menu, pumunta sa: "General"
   - Siguraduhing may check: [x] "Use the WSL 2 based engine"
3. Pumunta sa: "Resources" -> "WSL Integration"
   - Siguraduhing may check: [x] "Enable integration with my default WSL distro"
   - Kung may naka-install kang Ubuntu distro, i-ON ang toggle switch sa tabi nito.
4. I-click ang button sa ibaba: "Apply & restart"
EOF
}

# ------------------------------------------------------------------------------
# 5. HAKBANG 6 & 7: PAG-VERIFY AT TESTING
# ------------------------------------------------------------------------------
verify_docker() {
    print_title "HAKBANG 6: PAG-VERIFY SA INSTALLATION"

    print_info "Sinusuri ang Docker CLI:"
    if command -v docker &> /dev/null; then
        echo "  - Bersyon: $(docker --version)"
    else
        print_error "Hindi mahanap ang docker. Siguraduhing tapos na ang install."
        return 1
    fi

    print_info "Sinusuri ang Docker Compose:"
    if docker compose version &> /dev/null; then
        echo "  - Bersyon: $(docker compose version)"
    else
        print_error "Hindi mahanap ang docker compose."
        return 1
    fi

    print_info "Sinusuri ang koneksyon sa Docker Daemon:"
    if docker info &> /dev/null; then
        print_success "Bukas at maayos na tumatakbo ang Docker Desktop."
    else
        print_warn "Hindi maka-connect sa Docker. Buksan muna ang Docker Desktop app."
        return 1
    fi
}

test_docker() {
    print_title "HAKBANG 7: PAGSUBOK GAMIT ANG 'hello-world' CONTAINER"

    print_info "Pinapatakbo ang: docker run hello-world..."
    if docker run --rm hello-world; then
        echo ""
        print_success "Maayos na gumagana ang Docker sa iyong Windows PC."
    else
        echo ""
        print_error "May problema sa pagpapatakbo. Siguraduhing bukas ang Docker Desktop at naka-enable ang WSL2."
    fi
}

# ------------------------------------------------------------------------------
# 6. INTERACTIVE MENU
# ------------------------------------------------------------------------------
show_menu() {
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${GREEN}    GABAY SA PAG-INSTALL NG DOCKER SA WINDOWS         ${NC}"
    echo -e "${BLUE}======================================================${NC}"
    echo " 1) Hakbang 1: Check Windows Version & Virtualization"
    echo " 2) Hakbang 2 & 3: Setup at Update ng WSL2"
    echo " 3) Hakbang 4: I-install ang Docker Desktop (winget/web)"
    echo " 4) Hakbang 5: Mga Setting sa Loob ng Docker Desktop"
    echo " 5) Hakbang 6: I-verify ang Docker Installation"
    echo " 6) Hakbang 7: Patakbuhin ang Test Container (hello-world)"
    echo " 7) Sunod-sunod na patakbuhin lahat ng hakbang"
    echo " 0) Exit"
    echo -e "${BLUE}======================================================${NC}"
    read -rp "Pumili ng numero [0-7]: " choice

    case "$choice" in
        1) check_windows ;;
        2) setup_wsl2 ;;
        3) install_docker ;;
        4) explain_settings ;;
        5) verify_docker ;;
        6) test_docker ;;
        7)
            check_windows
            setup_wsl2
            install_docker
            explain_settings
            verify_docker
            test_docker
            ;;
        0) exit 0 ;;
        *) print_error "Maling numero. Pumili mula 0 hanggang 7.";;
    esac
}

# ------------------------------------------------------------------------------
# ENTRY POINT
# ------------------------------------------------------------------------------
case "$1" in
    win)        check_windows ;;
    wsl)        setup_wsl2 ;;
    install)    install_docker ;;
    config)     explain_settings ;;
    verify)     verify_docker ;;
    test)       test_docker ;;
    all)
        check_windows
        setup_wsl2
        install_docker
        explain_settings
        verify_docker
        test_docker
        ;;
    help|--help|-h)
        echo "Gamit: ./docker_installation_windows.sh [command]"
        echo ""
        echo "Mga Command:"
        echo "  win        Suriin ang Windows version at virtualization"
        echo "  wsl        I-setup at i-update ang WSL2"
        echo "  install    I-install ang Docker Desktop"
        echo "  config     Tingnan ang dapat i-set sa Docker Desktop app"
        echo "  verify     I-verify kung gumagana ang docker commands"
        echo "  test       Patakbuhin ang hello-world test container"
        echo "  all        Patakbuhin lahat ng hakbang nang sunod-sunod"
        echo "  (walang arg) Bubuksan ang interactive Tagalog menu"
        ;;
    *)
        if [ -n "$1" ]; then
            print_error "Hindi kilalang utos: $1"
            echo "Patakbuhin ang './docker_installation_windows.sh help' para sa gabay."
            exit 1
        else
            show_menu
        fi
        ;;
esac
