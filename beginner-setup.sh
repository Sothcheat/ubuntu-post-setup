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

  echo ""
    break
  fi
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

# === Fonts (FiraCode Nerd Font) ===
if confirm "🔤 Install FiraCode Nerd Font (programming-friendly font)?"; then
  step_start "📚 Installing FiraCode Nerd Font"
  mkdir -p ~/.local/share/fonts
  curl -Lf -o ~/.local/share/fonts/FiraCode.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
  unzip -o ~/.local/share/fonts/FiraCode.zip -d ~/.local/share/fonts/FiraCode
  fc-cache -fv
  step_end "FiraCode Nerd Font installed"
else
  log_warn "Skipped FiraCode Nerd Font installation"
fi

# === Minimal Zsh Setup ===
if confirm "Install Zsh shell with Oh My Zsh basic setup?"; then
  step_start "Installing Zsh and Oh My Zsh"

  sudo apt install -y zsh curl wget

  # Install Oh My Zsh (unattended)
  if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    log_info "Oh My Zsh already installed"
  fi

  # Create a minimal .zshrc
  cat > ~/.zshrc <<'EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source $ZSH/oh-my-zsh.sh
EOF

  log_info "Minimal .zshrc created with Oh My Zsh and git plugin."
  step_end "Zsh and Oh My Zsh installed"
else
  log_warn "Skipped Zsh and Oh My Zsh setup"
fi

# === Developer Tools ===
if confirm "🖥️ Install minimal development tools and languages (build-essential, git, python3, openjdk)?"; then
  step_start "📦 Installing development tools and languages"
  sudo apt install -y build-essential git python3-pip openjdk-21-jdk
  step_end "Development tools installed"
else
  log_warn "Skipped developer tools installation"
fi

# === IDEs Installation ===
if confirm "🖥️ Install developer IDEs (Visual Studio Code, IntelliJ IDEA Community, and NetBeans)?" ; then
  step_start "📦 Installing developer IDEs"

  # VS Code via apt (repo already added earlier)
  sudo apt install -y code

  step_end "Developer IDEs installed"
else
  log_warn "Skipped developer IDEs installation"
fi

# === Faster boot optimization ===
if confirm "⚡ Disable NetworkManager-wait-online.service for faster boot?"; then
  step_start "Disabling NetworkManager-wait-online.service"
  sudo systemctl disable NetworkManager-wait-online.service
  step_end "Disabled NetworkManager-wait-online.service"
else
  log_warn "Skipped disabling NetworkManager-wait-online.service"
fi

# === Enable firewall ===
step_start "🔥 Enabling UFW firewall"
sudo ufw --force enable
step_end "Firewall enabled"

# === Fonts and archive utilities ===
step_start "📂 Installing fonts and archive utilities"
sudo apt install -y cabextract fontconfig p7zip-full p7zip-rar unrar unzip
step_end "Fonts and archive utilities installed"

# === Final Message ===
log_info "🎉 Ubuntu 25.04 post-install setup completed. Please reboot if needed."

exit 0