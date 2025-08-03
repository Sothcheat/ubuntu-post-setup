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
  if confirm "Would you like to install drivers for another GPU (useful for hybrid setups)?"; then
    continue
  else
    break
  fi
done
step_end "GPU Drivers Installation Completed"

# === Multimedia codecs installation ===
step_start "🎵 Installing multimedia codecs (audio, video, DVD, MP3, etc.)"
sudo apt install -y ubuntu-restricted-extras libdvd-pkg
sudo dpkg-reconfigure libdvd-pkg -f noninteractive
step_end "Multimedia codecs installed — enjoy smooth playback."

# === Set hostname ===
step_start "🏷️ Setting hostname to 'ubuntu25'"
sudo hostnamectl set-hostname ubuntu25
step_end "Hostname set"

# === Essential applications install (includes Zen Browser via Flatpak) ===
if confirm "📦 Install essential applications (Zen Browser, Telegram, Discord, Kate, VLC)?"; then
  step_start "📥 Installing essential applications"

  # Install Zen Browser via Flatpak
  sudo flatpak install --noninteractive flathub app.zen_browser.zen

  # Install other apps via apt
  sudo apt install -y telegram-desktop discord kate vlc

  step_end "Essential applications installed"
else
  log_warn "Skipped installation of essential applications"
fi

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

# === Zsh with Oh My Zsh and Oh My Posh prompt ===
if confirm "🛠️ Install and configure Zsh shell with Oh My Zsh and Oh My Posh prompt?"; then
  step_start "⚙️ Installing Zsh, Oh My Zsh and Oh My Posh prompt setup"

  # Install Zsh and dependencies
  sudo apt install -y zsh curl unzip wget

  # Install Oh My Zsh (unattended)
  if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    log_info "Oh My Zsh already installed"
  fi

  # Set zsh as default shell if not already
  current_shell=$(getent passwd "$USER" | cut -d: -f7)
  zsh_path=$(command -v zsh)
  if [[ "$current_shell" != "$zsh_path" ]]; then
    chsh -s "$zsh_path"
    log_info "Default shell changed to Zsh"
  else
    log_info "Zsh already default shell"
  fi

  # Backup existing .zshrc first
  cp -n ~/.zshrc ~/.zshrc.backup-$(date +%Y%m%d_%H%M%S) || true

  # Create a minimal .zshrc with embedded plugin list and Oh My Zsh basics,
  # plus Oh My Posh configuration to replace prompt

  cat > ~/.zshrc <<'EOF'
# Path to Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Load Oh My Zsh framework
ZSH_THEME=""  # Theme disabled, using Oh My Posh instead

# Plugins as per gist from https://gist.github.com/n1snt/454b879b8f0b7995740ae04c5fb5b7df
plugins=(
    git 
    zsh-autosuggestions 
    zsh-syntax-highlighting 
    fast-syntax-highlighting 
    zsh-autocomplete
)

source $ZSH/oh-my-zsh.sh

# Load Oh My Posh prompt
eval "$(oh-my-posh init zsh --config ~/.poshthemes/atomic.omp.json)"

EOF

  log_info ".zshrc updated with Oh My Zsh plugins and Oh My Posh prompt configuration"

  # Install Oh My Posh binary (latest Linux AMD64 stable release)

  OMP_BIN_PATH="$HOME/.local/bin/oh-my-posh"
  mkdir -p "$(dirname "$OMP_BIN_PATH")"

  OMP_DOWNLOAD_URL=$(curl -s https://api.github.com/repos/JanDeDobbeleer/oh-my-posh/releases/latest | grep "browser_download_url.*linux_amd64" | cut -d '"' -f4)
  wget -qO "$OMP_BIN_PATH" "$OMP_DOWNLOAD_URL"
  chmod +x "$OMP_BIN_PATH"
  log_info "Oh My Posh binary installed to $OMP_BIN_PATH"

  # Download 'atomic' Oh My Posh theme JSON 
  mkdir -p ~/.poshthemes
  if [ ! -f ~/.poshthemes/atomic.omp.json ]; then
    wget -q -O ~/.poshthemes/atomic.omp.json https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/atomic.omp.json
    log_info "'atomic' Oh My Posh theme downloaded"
  else
    log_info "'atomic' Oh My Posh theme already exists"
  fi

  # Ensure ~/.local/bin is in PATH for future sessions
  if ! grep -q 'export PATH=$HOME/.local/bin:$PATH' ~/.zshrc; then
    echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.zshrc
    log_info "Added ~/.local/bin to PATH in .zshrc"
  fi

  step_end "Zsh with Oh My Zsh and Oh My Posh prompt installed and configured"

else
  log_warn "Skipped Zsh, Oh My Zsh and Oh My Posh setup"
fi

# === Developer Tools ===
if confirm "🖥️ Install development tools and languages (build-essential, git, python3, openjdk, nodejs, podman, docker)?"; then
  step_start "📦 Installing development tools and languages"
  sudo apt install -y build-essential git python3-pip openjdk-21-jdk nodejs npm podman docker.io
  sudo systemctl enable --now docker
  step_end "Development tools installed"
else
  log_warn "Skipped developer tools installation"
fi

# === IDEs Installation ===
if confirm "🖥️ Install developer IDEs (Visual Studio Code, IntelliJ IDEA Community, and NetBeans)?" ; then
  step_start "📦 Installing developer IDEs"

  # VS Code via apt (repo already added earlier)
  sudo apt install -y code

  # IntelliJ IDEA Community Edition via Flatpak
  sudo flatpak install --noninteractive flathub org.jetbrains.IntelliJ-IDEA-Community

  # NetBeans IDE via Flatpak
  sudo flatpak install --noninteractive flathub org.apache.netbeans

  step_end "Developer IDEs installed"
else
  log_warn "Skipped developer IDEs installation"
fi

# === Desktop Customization ===
step_start "🎨 Customize Ubuntu"
echo "Pick your Desktop Environment you're running on."

while true; do
  echo -e "\nSelect your Desktop Environment:"
  echo " 1) GNOME"
  echo " 2) KDE Plasma"
  echo " 3) Skip customization"
  log_prompt "Enter choice [1-3]: "
  read -r de_choice
  case "$de_choice" in
    1)
      log_info "You chose GNOME."
      step_start "Installing GNOME Customization Applications"
      sudo apt install -y gnome-tweaks
      flatpak install --noninteractive flathub com.mattjakeman.ExtensionManager || log_warn "Flatpak not installed or failed"
      step_end "GNOME Customization installation"
      break
      ;;
    2)
      log_info "You chose KDE Plasma."
      step_start "Installing KDE Plasma Customization Applications"
      sudo apt install -y kvantum
      step_end "KDE Plasma Customization installation"
      break
      ;;
    3)
      log_warn "Skipping customization as requested."
      break
      ;;
    *)
      echo "❌ Invalid option. Please enter a number between 1 and 3."
      ;;
  esac
done
step_end "Desktop Customization completed."

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