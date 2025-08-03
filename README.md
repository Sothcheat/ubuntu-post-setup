# Ubuntu 25.04 Post-Install Setup

Automated post-installation setup scripts for Ubuntu 25.04 Desktop tailored for different user needs: a minimal beginner-friendly setup, and a comprehensive personal/developer setup with advanced features.

This repository contains two scripts:

- **`beginner-setup.sh`** — A minimal and universal setup script meant for beginners or general users who want to quickly install essential drivers, codecs, fonts, and utilities with minimal customization.
- **`personal-setup.sh`** — A full-featured script for personal or developer use, including IDEs, extensive developer tools, custom terminal theming, GPU driver selection, and desktop environment tweaking.

## Quick Start

You can run either script directly from the internet with a single command.

### Beginner-Friendly Setup (Minimal)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Sothcheat/ubuntu-post-setup/main/beginner-setup.sh)"
```

or with `wget`:

```bash
/bin/bash -c "$(wget -qO- https://raw.githubusercontent.com/Sothcheat/ubuntu-post-setup/main/beginner-setup.sh)"
```

### Personal Full Setup (Developer & Power User)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Sothcheat/ubuntu-post-setup/main/personal-setup.sh)"
```

or with `wget`:

```bash
/bin/bash -c "$(wget -qO- https://raw.githubusercontent.com/Sothcheat/ubuntu-post-setup/main/personal-setup.sh)"
```

## Features Overview

### Common Features in Both Scripts

- Enable essential Ubuntu repositories (`main`, `universe`, `restricted`, `multiverse`).
- Setup Flathub Flatpak repository for latest Flatpak apps.
- Interactive GPU driver installation for NVIDIA, AMD, and Intel.
- Multimedia codecs installation for audio and video playback.
- Essential fonts installation, including FiraCode Nerd Font.
- System updates and upgrades.
- Firewall (UFW) enabled by default.
- Installation of some core utilities and archive tools.

### Additional Features in `personal-setup.sh`

- Installation of advanced developer tools and languages including:
  - Build tools (`build-essential`), Git, Python 3, OpenJDK, Node.js, Docker, and Podman.
- IDEs installation:
  - Visual Studio Code (via Microsoft repository)
  - IntelliJ IDEA Community Edition (via Flatpak)
  - Apache NetBeans IDE (via Flatpak)
- Zsh shell setup with **Oh My Zsh** and **Oh My Posh** prompt with a custom terminal theme.
- Desktop environment-specific customizations (GNOME and KDE Plasma tweaks).
- Hostname setting and faster boot optimizations.
- Comprehensive logging of all script actions.
- User-friendly prompts with ability to skip sections as preferred.

## Important Notes

- You must have an active internet connection for the scripts to work properly.
- **Secure Boot** should be disabled if you intend to install proprietary NVIDIA drivers without manual kernel module signing.
- Scripts prompt for your confirmation at each major step, so they are safe to run unattended or interactively.
- Log files are stored in `~/ubuntu25-setup-logs/` for troubleshooting and review.
- A system reboot is recommended after script completion to finalize installations.
- Review and customize the script as needed before running to fit your preferences.

## Manual Usage

If you prefer to use the scripts locally or edit them before running, clone the repository:

```bash
git clone https://github.com/Sothcheat/ubuntu-post-setup.git
cd ubuntu-post-setup
chmod +x beginner-setup.sh personal-setup.sh

# Run the beginner setup script
./beginner-setup.sh

# Or run the full personal setup script
./personal-setup.sh
```

## Support and Contributions

- Feel free to open issues for bug reports, feature requests, or questions.
- Pull requests are welcome to improve or add new features.
- You can customize these scripts to suit your own workflow or hardware.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for full details.

© 2025 Sothcheat Bunna

*Happy Ubuntu 25.04 setup!* 🎉