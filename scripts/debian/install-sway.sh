#!/bin/bash

echo -e "\e[1m----------------------------------------------------\e[0m"
echo -e "\e[1mInstalling Sway window manager and additional utils.\e[0m"
echo -e "\e[1m----------------------------------------------------\e[0m"

read -p "Start installation? (y/N): " confirm
[[ "$confirm" != "y" ]] && exit 1

sudo apt update
sudo apt install -y sway swaybg swaylock swayidle fuzzel mako-notifier rofi waybar network-manager-gnome mate-polkit pulseaudio-utils xdg-desktop-portal-wlr || { echo "\e[1mInstallation failed!\e[0m"; exit 1; }

echo -e "\e[1mInstallation complete!\e[0m"
