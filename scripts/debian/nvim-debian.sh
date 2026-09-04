#!/usr/bin/env bash

# Before running script, make sure brew is in $PATH.

set -euo pipefail

echo -e "\e[1m------------------\e[0m"
echo -e "\e[1mINSTALLING NEOVIM.\e[0m"
echo -e "\e[1m------------------\e[0m"

read -p "Start installation? (y/N): " confirm
[[ "$confirm" != "y" ]] && exit 1

echo -e "\e[1mInstalling Neovim.\e[0m"
brew update
brew install neovim gcc

echo -e "\e[1mInstalling dependencies.\e[0m"
sudo apt update
sudo apt install luarocks fzf wl-clipboard

echo -e "\e[1mInstallation complete!\e[0m"
