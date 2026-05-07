#!/bin/bash

# README
# Make sure it's excetutable with 'chmod +x ./<name>

echo -e "\e[1m--------------------\e[0m"
echo -e "\e[1mSetting up SSH keys.\e[0m"
echo -e "\e[1m--------------------\e[0m"

read -p "Continue? (y/N): " confirm
[[ "$confirm" != "y" ]] && exit 1

read -p "Please add <user@hostname>: " host
[ -z "$host" ] && { echo "No user@hostname."; exit 1; }

ssh-keygen -t ed25519 -C "$host"

chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519 
chmod 644 ~/.ssh/id_ed25519.pub

# added 7.5 2026
eval $(ssh-agent)

ssh-add ~/.ssh/id_ed25519
