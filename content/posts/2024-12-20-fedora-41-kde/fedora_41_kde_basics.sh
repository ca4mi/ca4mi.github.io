#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to print messages
print_message() {
    echo "--------------------------------------------------"
    echo "$1"
    echo "--------------------------------------------------"
}

# Update system
print_message "Updating system..."
sudo dnf update -y

# Add RPM Fusion repositories
print_message "Checking for RPM Fusion repositories..."

RPM_FUSION_FREE="/etc/yum.repos.d/rpmfusion-free.repo"
RPM_FUSION_NONFREE="/etc/yum.repos.d/rpmfusion-nonfree.repo"

if [ -f "$RPM_FUSION_FREE" ] && [ -f "$RPM_FUSION_NONFREE" ]; then
    print_message "RPM Fusion repositories already exist. Skipping addition."
else
    print_message "Adding RPM Fusion repositories..."
    sudo dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
fi

# Install Nvidia drivers
print_message "Installing nvidia drivers..."
sudo dnf install -y akmod-nvidia
sudo dnf install -y xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-cuda-libs

# Install additional applications via dnf
print_message "Installing additional applications via dnf..."
sudo dnf install -y btop kitty syncthing podman-compose fastfetch vim git git-crypt

# Install Mullvad VPN
print_message "Checking for Mullvad repository..."

if [ -f /etc/yum.repos.d/mullvad.repo ]; then
    print_message "Mullvad repository already exists. Skipping addition."
else
    print_message "Adding Mullvad repository..."
    wget https://repository.mullvad.net/rpm/stable/mullvad.repo
    sudo dnf config-manager addrepo --from-repofile=mullvad.repo
    rm -rf mullvad.repo
fi

print_message "Installing Mullvad VPN..."
sudo dnf update --refresh
sudo dnf install -y mullvad-vpn || {
    print_message "Failed to install Mullvad VPN."
    exit 1
}

# Add Flathub repository for Flatpak
print_message "Adding Flathub repository for Flatpak..."
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
sudo flatpak remote-modify --enable flathub

# Install applications via Flatpak
print_message "Installing applications via Flatpak..."
flatpak install -y Flathub \
    org.darktable.Darktable \
    org.kde.kdenlive \
    org.videolan.VLC \
    com.anydesk.Anydesk \
    com.jeffser.Alpaca \
    com.valvesoftware.Steam \
    com.obsproject.Studio \
    io.github.zen_browser.zen \
    md.obsidian.Obsidian \
    net.mullvad.MullvadBrowser \
    com.google.Chrome \
    net.lutris.Lutris \
    dev.zed.Zed

# Install EnvyControl
print_message "Installing EnvyControl..."
sudo dnf copr enable sunwire/envycontrol -y
sudo dnf install python3-envycontrol
# Install Optimus GPU Switcher widget
# Variables
REPO_URL="https://github.com/enielrodriguez/optimus-gpu-switcher.git"
BRANCH="main-kde6"
TARGET_DIR="$HOME/optimus-gpu-switcher"

echo "Cloning the repository..."
if git clone --branch $BRANCH $REPO_URL $TARGET_DIR; then
    echo "Repository cloned successfully."
else
    echo "Error cloning repository. Skipping..."
fi

# Install the widget using kpackagetool6
echo "Installing the widget..."
if kpackagetool6 -t Plasma/Applet -i $TARGET_DIR; then
    echo "Widget installed successfully."
else
    echo "Error installing the widget. Skip..."
fi

# Clean up
echo "Cleaning up temporary files..."
rm -rf $TARGET_DIR

# Clone and install Dusal Bicheech keyboard layout
print_message "Installing Dusal Bicheech keyboard layout..."
git clone https://github.com/almas/Dusal_Bicheech_XKB
cd Dusal_Bicheech_XKB/
chmod +x Dusal_bicheech.sh
./Dusal_bicheech.sh
cd ..
rm -rf Dusal_Bicheech_XKB

print_message "Completed successfully!"
