#!/usr/bin/env bash
set -euo pipefail

echo -e "\e[1m------------------\e[0m"
echo -e "\e[1mINSTALLING NEOVIM.\e[0m"
echo -e "\e[1m------------------\e[0m"

read -p "Start installation? (y/N): " confirm
[[ "$confirm" != "y" ]] && exit 1

echo -e "\e[1mInstalling Neovim.\e[0m"
sudo pacman -Syu
sudo pacman -S neovim

echo -e "\e[1mInstalling dependencies.\e[0m"
sudo pacman -S python ruby luarocks lua51 fzf fd wl-clipboard

echo -e "\e[1mInstallation complete!\e[0m"
