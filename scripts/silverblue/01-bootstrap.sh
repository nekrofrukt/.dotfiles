#!/usr/bin/env bash
set -euo pipefail

echo -e " "
echo -e "\e[1mSilverblue bootstrap.\e[0m"
echo -e "\e[1m---\e[0m"

# Probably handled by layering.
#echo -e " "
#echo -e "Upgrading system."
#sudo rpm-ostree upgrade
#echo -e " "

echo -e "Layering additional packages."
sudo rpm-ostree install tailscale stow
echo -e " "

if [ ! -d ~/.dotfiles/.git ]; then
    echo -e "Cloning dotfiles repo."
    cd
    git clone https://github.com/nekrofrukt/.dotfiles.git
else
    echo -e "dotfiles repo already present, pulling latest."
    cd
    git -C ~/.dotfiles pull --ff-only
fi

echo -e "\e[1mReboot required to activate the layered packages.\e[0m"
read -rp "Reboot now? (y/N): " reboot
if [[ "$reboot" == "y" ]]; then
    echo -e "\e[1mRebooting.\e[0m"
    systemctl reboot
fi

exit 0
