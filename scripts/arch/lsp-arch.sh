#!/usr/bin/env bash
set -euo pipefail

echo -e "\e[1m \e[0m"
echo -e "\e[1mIntalling LSP servers.\e[0m"
echo -e "\e[1m---\e[0m"

read -p "Start installation? (y/N): " confirm
[[ "$confirm" != "y" ]] && exit 1

sudo pacman -Syu
sudo pacman -S lua-language-server

#echo -e "\e[1mInstalling dependencies.\e[0m"
#sudo pacman -S 

echo -e "\e[1mInstallation complete!\e[0m"
