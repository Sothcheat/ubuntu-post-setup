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
log_info()  { echo -e "${GREEN}✅ [INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}⚠️ [WARN]${NC} $*"; }
log_error() { echo -e "${RED}❌ [ERROR]${NC} $*" >&2; }
log_prompt(){ echo -ne "${BLUE}❓ [INPUT]${NC} $*"; }

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
      echo " $((i + 1))) ${options[$i]}"
    done
    log_prompt "➡️ Enter choice [1-${#options[@]}]: "
    read -r opt
    if [[ "$opt" =~ ^[1-9][0-9]*$ ]] && ((opt >= 1 && opt <= ${#options[@]})); then
      echo "${options[$((opt - 1))]}"
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
# Fix: Use proper syntax for add-apt-repository
sudo add-apt-repository -y main universe restricted multiverse
sudo apt update
step_end "Essential Ubuntu repositories enabled"

# === Enable Flathub Flatpak Repository ===
step_start "📦 Enabling Flathub Flatpak repository"
sudo apt install -y flatpak
# Fix: Add gnome-software-plugin-flatpak for GNOME integration
if dpkg -l | grep -q gnome-shell; then
  sudo apt install -y gnome-software-plugin-flatpak
fi
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
step_end "Flathub Flatpak repository enabled"

# === Add Microsoft VS Code Repository ===
step_start "📦 Adding Microsoft VS Code repository"
# Fix: Use proper directory and error handling
if [ ! -f /usr/share/keyrings/packages.microsoft.gpg ]; then
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
  sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
  echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
  sudo apt update
  rm -f packages.microsoft.gpg
fi
step_end "Microsoft VS Code repository added"

# === System update & upgrade ===
step_start "🔄 System update and upgrade"
sudo apt update
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
        # Fix: Check if ubuntu-drivers exists
        if command -v ubuntu-drivers &>/dev/null; then
          sudo ubuntu-drivers autoinstall
        else
          sudo apt install -y nvidia-driver-535
        fi
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
        # Fix: i965-va-driver-shaders doesn't exist, use i965-va-driver
        sudo apt install -y mesa-va-drivers intel-media-va-driver i965-va-driver vainfo vulkan-utils
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
  break
done
step_end "GPU Drivers Installation Completed"

# === Multimedia codecs installation ===
step_start "🎵 Installing multimedia codecs (audio, video, DVD, MP3, etc.)"
# Fix: Handle potential dialog issues
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
sudo apt install -y ubuntu-restricted-extras libdvd-pkg
sudo DEBIAN_FRONTEND=noninteractive dpkg-reconfigure libdvd-pkg
step_end "Multimedia codecs installed — enjoy smooth playback."

# === Set hostname ===
step_start "🏷️ Setting hostname to 'ubuntu25'"
sudo hostnamectl set-hostname ubuntu25
# Fix: Update /etc/hosts too
sudo sed -i "s/127.0.1.1.*/127.0.1.1\tubuntu25/" /etc/hosts
step_end "Hostname set"

# === Essential applications install (Zen Browser via Flatpak and Ghostty) ===

if confirm "📦 Install essential applications (Zen Browser, Telegram, Discord, Kate, VLC, Ghostty)?"; then

  step_start "📥 Installing essential applications"

  # Install curl first (required for Ghostty)
  if ! command -v curl &>/dev/null; then
    sudo apt install -y curl
  fi

  # Fix: Check if snap is available before using it
  if command -v snap &>/dev/null; then
    # Install Ghostty via snap
    sudo snap install ghostty --classic || log_warn "Failed to install Ghostty via snap"
  else
    log_warn "Snap not available, skipping Ghostty installation"
  fi

  # Install Zen Browser via Flatpak
  sudo flatpak install -y --noninteractive flathub io.github.zen_browser.zen || log_warn "Failed to install Zen Browser"

  # Fix: Don't remove Firefox by default, let user decide
  if confirm "Remove Firefox browser?"; then
    sudo apt remove -y firefox
  fi

  # Install other apps via apt
  sudo apt install -y kate vlc

  # Install Telegram-desktop and Discord via flatpak
  flatpak install -y --noninteractive flathub org.telegram.desktop || log_warn "Failed to install Telegram"
  flatpak install -y --noninteractive flathub com.discordapp.Discord || log_warn "Failed to install Discord"

  step_end "Essential applications installed"

fi

# === Fonts (FiraCode Nerd Font) ===

if confirm "🔤 Install FiraCode Nerd Font (programming-friendly font)?"; then

  step_start "📚 Installing FiraCode Nerd Font"

  mkdir -p ~/.local/share/fonts

  # Fix: Use temporary directory for download
  TEMP_DIR=$(mktemp -d)
  cd "$TEMP_DIR"
  
  curl -Lf -o FiraCode.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip

  unzip -o FiraCode.zip -d ~/.local/share/fonts/FiraCode

  fc-cache -fv

  cd - > /dev/null
  rm -rf "$TEMP_DIR"

  step_end "FiraCode Nerd Font installed"

else

  log_warn "Skipped FiraCode Nerd Font installation"

fi

# === Developer Tools ===

if confirm "🖥️ Install development tools and languages (build-essential, git, python3, openjdk, nodejs, podman, docker)?"; then

  step_start "📦 Installing development tools and languages"

  # Fix: Separate installations and add python3-venv
  sudo apt install -y build-essential git python3-pip python3-venv
  sudo apt install -y openjdk-21-jdk || sudo apt install -y default-jdk
  sudo apt install -y nodejs npm
  
  # Container tools
  if confirm "Install container tools (Podman and Docker)?"; then
    sudo apt install -y podman
    sudo apt install -y docker.io docker-compose
    sudo systemctl enable --now docker
    # Fix: Add user to docker group
    sudo usermod -aG docker $USER || true
    log_info "You'll need to log out and back in for docker group changes to take effect"
  fi

  step_end "Development tools installed"

else

  log_warn "Skipped developer tools installation"

fi

# === Zsh with Oh My Zsh and Oh My Posh prompt ===

if confirm "🛠️ Install and configure Zsh shell with Oh My Zsh and Oh My Posh prompt?"; then

  step_start "⚙️ Installing Zsh, Oh My Zsh and Oh My Posh prompt setup"

  sudo apt install -y zsh curl unzip wget git

  # Install Oh My Zsh (unattended)
  if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    log_info "Oh My Zsh already installed"
  fi

  # Install Oh My Zsh plugins
  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  
  # zsh-autosuggestions
  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  fi
  
  # zsh-syntax-highlighting
  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  fi
  
  # fast-syntax-highlighting
  if [ ! -d "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" ]; then
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"
  fi
  
  # zsh-autocomplete
  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autocomplete" ]; then
    git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git "$ZSH_CUSTOM/plugins/zsh-autocomplete"
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
  if [ -f ~/.zshrc ]; then
    cp ~/.zshrc ~/.zshrc.backup-$(date +%Y%m%d_%H%M%S)
  fi

  # Download the .zshrc from the gist
  log_info "Downloading .zshrc configuration from gist..."
  wget -q -O ~/.zshrc https://gist.githubusercontent.com/n1snt/454b879b8f0b7995740ae04c5fb5b7df/raw/.zshrc || {
    log_warn "Failed to download .zshrc from gist, creating custom configuration"
    
    # Create a custom .zshrc if download fails
    cat >~/.zshrc <<'EOF'
# Path to Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme disabled, using Oh My Posh instead
ZSH_THEME=""

# Plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    fast-syntax-highlighting
    zsh-autocomplete
    docker
    docker-compose
    sudo
    command-not-found
    colored-man-pages
    colorize
    cp
    extract
)

source $ZSH/oh-my-zsh.sh

# User configuration
export PATH=$HOME/.local/bin:$PATH

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Load Oh My Posh prompt
if command -v oh-my-posh &> /dev/null; then
    eval "$(oh-my-posh init zsh --config ~/.poshthemes/atomic.omp.json)"
fi
EOF
  }

  # Install Oh My Posh binary
  log_info "Installing Oh My Posh..."
  mkdir -p "$HOME/.local/bin"
  
  # Fix: Better Oh My Posh installation
  if ! command -v oh-my-posh &>/dev/null; then
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
    chmod +x "$HOME/.local/bin/oh-my-posh"
  fi

  # Download atomic theme
  mkdir -p ~/.poshthemes
  wget -q -O ~/.poshthemes/atomic.omp.json https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/atomic.omp.json

  # Ensure PATH is set in .zshrc
  if ! grep -q 'export PATH=$HOME/.local/bin:$PATH' ~/.zshrc; then
    echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.zshrc
  fi

  # Add Oh My Posh to .zshrc if not already there
  if ! grep -q "oh-my-posh init zsh" ~/.zshrc; then
    echo 'eval "$(oh-my-posh init zsh --config ~/.poshthemes/atomic.omp.json)"' >> ~/.zshrc
  fi

  step_end "Zsh with Oh My Zsh and Oh My Posh prompt installed and configured"

else

  log_warn "Skipped Zsh, Oh My Zsh and Oh My Posh setup"

fi

# === Ghostty terminal configuration ===

if command -v ghostty &> /dev/null; then
  step_start "🖥️ Configuring Ghostty terminal"

  GHOSTTY_CONFIG_DIR="$HOME/.config/ghostty"
  GHOSTTY_CONFIG_FILE="$GHOSTTY_CONFIG_DIR/config"
  mkdir -p "$GHOSTTY_CONFIG_DIR"

  cat > "$GHOSTTY_CONFIG_FILE" <<EOF
# Font configuration
font-family = FiraCode Nerd Font
font-size = 14

# Appearance
background-opacity = 0.9
theme = Everforest Dark - Hard
cursor-style = block
cursor-style-blink = true

# Window settings
window-padding-x = 4
window-padding-y = 4
window-decoration = true

# Terminal behavior
scrollback-limit = 10000
mouse-hide-while-typing = true

# Performance
unfocused-split-opacity = 0.7
link-url = true
copy-on-select = false
confirm-close-surface = false

EOF

  log_info "Ghostty config written to $GHOSTTY_CONFIG_FILE"
  step_end "Ghostty terminal configured"
else
  log_warn "Ghostty not found, skipping configuration"
fi

# === IDEs Installation ===

if confirm "🖥️ Install developer IDEs (Visual Studio Code, IntelliJ IDEA Community, and NetBeans)?"; then

  step_start "📦 Installing developer IDEs"

  # VS Code via apt (repo already added earlier)
  sudo apt install -y code || log_warn "Failed to install VS Code"

  # IntelliJ IDEA Community Edition via Flatpak
  sudo flatpak install -y --noninteractive flathub com.jetbrains.IntelliJ-IDEA-Community || log_warn "Failed to install IntelliJ IDEA"

  # NetBeans IDE via Flatpak
  sudo flatpak install -y --noninteractive flathub org.apache.netbeans || log_warn "Failed to install NetBeans"

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
  echo " 2) Skip customization"
  log_prompt "Enter choice [1-2]: "
  read -r de_choice

  case "$de_choice" in
    1)
      log_info "You chose GNOME."
      step_start "Installing GNOME Customization Applications"
      sudo apt install -y gnome-tweaks gnome-shell-extensions
      flatpak install -y --noninteractive flathub com.mattjakeman.ExtensionManager || log_warn "Failed to install Extension Manager"
      step_end "GNOME Customization installation"
      break
      ;;
    2)
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
  sudo systemctl disable NetworkManager-wait-online.service || log_warn "Failed to disable NetworkManager-wait-online.service"
  step_end "Disabled NetworkManager-wait-online.service"
else
  log_warn "Skipped disabling NetworkManager-wait-online.service"
fi

# === Enable firewall ===

step_start "🔥 Enabling UFW firewall"
sudo ufw --force enable || log_warn "Failed to enable firewall"
step_end "Firewall enabled"

# === Fonts and archive utilities ===

step_start "📂 Installing fonts and archive utilities"
sudo apt install -y cabextract fontconfig p7zip-full p7zip-rar unrar unzip || {
  # Fix: p7zip-rar might not be available in all repos
  sudo apt install -y cabextract fontconfig p7zip-full unrar unzip
}
step_end "Fonts and archive utilities installed"

# === Cleanup ===
step_start "🧹 Cleaning up"
sudo apt autoremove -y
sudo apt autoclean
step_end "Cleanup completed"

# === Final Message ===

echo -e "\n${GREEN}🎉 Ubuntu 25.04 post-install setup completed!${NC}"
echo -e "${YELLOW}⚠️  Important notes:${NC}"
echo "  1. A reboot is recommended to ensure all changes take effect"
echo "  2. If you installed Docker, log out and back in for group changes"
echo "  3. If you changed to Zsh, restart your terminal or run: exec zsh"
echo "  4. Check the log file for any warnings: $LOGFILE"

if confirm "Would you like to reboot now?"; then
  sudo reboot
fi

exit 0
