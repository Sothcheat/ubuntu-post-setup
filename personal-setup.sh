#!/bin/bash

# Ubuntu 25.04 Post-Install Setup Script

set -euo pipefail
IFS=$'\n\t'

trap 'log_error "Script failed at line $LINENO. Check $LOGFILE for details."' ERR

# === Setup Logging ===
LOG_DIR="$HOME/ubuntu25-setup-logs"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/ubuntu25-setup-$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOGFILE") 2>&1

# === Colors ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# === Functions ===
log_info()    { echo -e "${GREEN}✅ [INFO]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}⚠️ [WARN]${NC} $*"; }
log_error()   { echo -e "${RED}❌ [ERROR]${NC} $*" >&2; }
log_prompt()  { echo -ne "${BLUE}❓ [INPUT]${NC} $*"; }

confirm() {
  while true; do
    log_prompt "$1 [y/n]: "
    read -r ans
    case "$ans" in
      [Yy]*) return 0 ;;
      [Nn]*) return 1 ;;
      *) echo "Please answer y or n." ;;
    esac
  done
}

check_internet() {
  log_info "🌐 Checking internet connectivity..."
  if ! ping -c1 -W2 8.8.8.8 &>/dev/null; then
    log_error "No internet connectivity detected. Please check your network."
    exit 1
  fi
  log_info "🌐 Internet connectivity confirmed."
}

choose_option() {
  local prompt="$1"
  shift
  local options=("$@")
  local opt
  while true; do
    echo -e "${CYAN}📋 ${prompt}${NC}"
    for i in "${!options[@]}"; do
      echo " $((i+1))) ${options[$i]}"
    done
    log_prompt "➡️ Enter choice [1-${#options[@]}]: "
    read -r opt
    if [[ "$opt" =~ ^[1-9][0-9]*$ ]] && (( opt >= 1 && opt <= ${#options[@]} )); then
      echo "${options[$((opt-1))]}"
      return 0
    fi
    echo "❗ Invalid option. Try again."
  done
}

step_start() {
  echo -e "\n${CYAN}🔧 ==> Starting: $* ...${NC}"
  date +"[%Y-%m-%d %H:%M:%S] Starting: $*" >> "$LOGFILE"
}

step_end() {
  echo -e "${CYAN}✔️ ==> Completed: $*${NC}\n"
  date +"[%Y-%m-%d %H:%M:%S] Completed: $*" >> "$LOGFILE"
}

# === Start Script ===

clear
echo -e "${GREEN}🚀 Ubuntu 25.04 Post-Install Setup Script${NC}"
echo "📄 Log file: $LOGFILE"

check_internet

# === Enable Essential Ubuntu Repositories ===
step_start "📦 Enabling essential Ubuntu repositories (main, universe, restricted, multiverse)"
sudo add-apt-repository -y main
sudo add-apt-repository -y universe
sudo add-apt-repository -y restricted
sudo add-apt-repository -y multiverse
sudo apt update
step_end "Essential Ubuntu repositories enabled"

# === Enable Flathub Flatpak Repository ===
step_start "📦 Enabling Flathub Flatpak repository"
sudo apt install -y flatpak
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
step_end "Flathub Flatpak repository enabled"

# === Add Microsoft VS Code Repository ===
step_start "📦 Adding Microsoft VS Code repository"
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
sudo apt update
rm packages.microsoft.gpg
step_end "Microsoft VS Code repository added"

# === System update & upgrade ===
step_start "🔄 System update and upgrade"
sudo apt -y upgrade
step_end "System updated and upgraded"

# === Beginner-Friendly GPU Driver Installation ===
step_start "🖥️ GPU Drivers Installation"
echo "Welcome! Please select your GPU brand to install the best drivers."
echo "Note: Installing drivers may take some minutes."
echo "You can run this multiple times if you have multiple GPUs (e.g., Intel + NVIDIA)."

while true; do
  echo -e "\nSelect your GPU brand:"
  echo " 1) NVIDIA"
  echo " 2) AMD"
  echo " 3) Intel"
  echo " 4) None / Skip GPU driver installation"
  log_prompt "Enter choice [1-4]: "
  read -r gpu_choice

  case "$gpu_choice" in
    1)
      log_info "You chose NVIDIA GPU."
      echo "⚠️ NVIDIA driver installation may take time while kernel modules build."
      if confirm "Proceed with NVIDIA driver installation?"; then
        step_start "Installing NVIDIA drivers"
        sudo ubuntu-drivers autoinstall
        sudo systemctl enable --now nvidia-persistenced || true
        log_info "✅ NVIDIA drivers installed."
        step_end "NVIDIA drivers installation"
      else
        log_warn "Skipped NVIDIA driver installation."
      fi
      ;;
    2)
      log_info "You chose AMD GPU."
      echo "⚠️ AMD Mesa and Vulkan drivers installation may take a couple of minutes."
      if confirm "Proceed with AMD driver installation?"; then
        step_start "Installing AMD GPU drivers"
        sudo apt install -y mesa-va-drivers mesa-vdpau-drivers mesa-vulkan-drivers mesa-utils
        log_info "✅ AMD GPU drivers installed."
        step_end "AMD drivers installation"
      else
        log_warn "Skipped AMD driver installation."
      fi
      ;;
    3)
      log_info "You chose Intel integrated GPU."
      echo "⚠️ Intel drivers and media acceleration installation may take a minute."
      if confirm "Proceed with Intel driver installation?"; then
        step_start "Installing Intel GPU drivers"
        sudo apt install -y mesa-va-drivers intel-media-va-driver i965-va-driver-shaders vainfo vulkan-utils
        log_info "✅ Intel GPU drivers installed."
        step_end "Intel drivers installation"
      else
        log_warn "Skipped Intel driver installation."
      fi
      ;;
    4)
      log_warn "Skipping GPU driver installation as requested."
      break
      ;;
    *)
      echo "❌ Invalid option. Please enter a number between 1 and 4."
      continue
      ;;
  esac

  # Removed unnecessary and unmatched 'if' statement below; it caused an error.
  # There was a stray 'fi' after this loop.

  # After processing selection once, break to avoid infinite loop
  break
done
step_end "GPU Drivers Installation Completed"

# === Multimedia codecs installation ===
step_start "🎵 Installing multimedia codecs (audio, video, DVD, MP3, etc.)"
sudo apt install -y ubuntu-restricted-extras libdvd-pkg
sudo DEBIAN_FRONTEND=noninteractive dpkg-reconfigure libdvd-pkg
step_end "Multimedia codecs installed — enjoy smooth playback."

# === Set hostname ===
step_start "🏷️ Setting hostname to 'ubuntu25'"
sudo hostnamectl set-hostname ubuntu25
step_end "Hostname set"

# The rest of your script continues as is...
