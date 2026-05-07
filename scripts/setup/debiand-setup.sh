#!/usr/bin/env bash
set -euo pipefail

echo -e "\e[1m-------------------------\e[0m"
echo -e "\e[1mDEBIAN BASE SYSTEM SETUP.\e[0m"
echo -e "\e[1m-------------------------\e[0m"

read -p "Start installation? (y/N): " confirm
[[ "$confirm" != "y" ]] && exit 1

echo -e "\e[1mConfiguring gsettings. ~~>\e[0m"

gsettings set org.gnome.desktop.peripherals.keyboard delay 200
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 30
echo -e "\e[1mKeyboard delay set to '200'.\e[0m"
echo -e "\e[1mKeyboard repeat-interval set to '30'.\e[0m"
echo -e "\e[1m---\e[0m"

echo -e "\e[1mInstalling utils.\e[0m"

# BASE UTILS
sudo apt update
sudo apt install -y git curl wget lsb-release

# REPOSITORIES
echo -e "\e[1mAdding repositories.\e[0m"

# 1password
curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list

sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

# Brave Browser
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources https://brave-browser-apt-release.s3.brave.com/brave-browser.sources

# Griffo.io
curl -sS https://debian.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/debian.griffo.io.gpg
echo "deb https://debian.griffo.io/apt $(lsb_release -sc 2>/dev/null) main" | sudo tee /etc/apt/sources.list.d/debian.griffo.io.list

# Dropbox
wget https://linux.dropbox.com/packages/debian/dropbox_2026.01.15_amd64.deb -O /tmp/dropbox.deb

# Spotify
curl -sS https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list

# NordVPN
sh <(wget -qO - https://downloads.nordcdn.com/apps/linux/install.sh) -p nordvpn-gui

# Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Signal
wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg;
cat signal-desktop-keyring.gpg | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
rm signal-desktop-keyring.gpg signal-desktop.sources

# Packages
echo -e "\e[1mInstalling packages.\e[0m"

sudo apt update
sudo apt install -y 1password brave-browser ghostty flatpak gnome-software-plugin-flatpak ripgrep ufw tree starship fastfetch nordvpn spotify-client vlc btop transmission ranger signal-desktop /tmp/dropbox.deb

echo -e "\e[1mEnabling firewall.\e[0m"
sudo ufw enable

# Flatpak
echo -e "\e[1mSetting up Flatpak repository.\e[0m"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo -e "\e[1mInstallation complete!\e[0m"
