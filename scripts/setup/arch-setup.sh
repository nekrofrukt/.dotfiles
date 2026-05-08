#!/usr/bin/env bash
set -euo pipefail

echo -e "\e[1m-----------------------\e[0m"
echo -e "\e[1mARCH BASE SYSTEM SETUP.\e[0m"
echo -e "\e[1m-----------------------\e[0m"

read -p "Start installation? (y/N): " confirm
[[ "$confirm" != "y" ]] && exit 1

echo -e "\e[1mInstalling utils.\e[0m"

# BASE UTILS
sudo pacman -Syu
sudo pacman -S base-devel blueman fastfetch firefox foot gnome-disk-utility gnome-text-editor ttf-jetbrains-mono-nerd man-db man-pages ranger ripgrep rofi starship sushi tree vlc wl-clipboard

echo -e "\e[1mEnabling firewall.\e[0m"
sudo ufw enable

echo -e "\e[1mInstallation complete!\e[0m"
