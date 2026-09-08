#!/usr/bin/env bash
set -euo pipefail

command -v mise >/dev/null || { echo "mise not on PATH — run 01-bootstrap.sh first"; exit 1; }

cd
cd .dotfiles
mv ~/.bashrc ~/.bashrc.bak
mkdir -p ~/.config/mise
stow bashrc-silverblue
stow mise-silverblue

if [ ! -f "$HOME/.config/mise/config.toml" ]; then
    echo "warning: ~/.config/mise/config.toml missing — stow it first."
fi

echo -e "Installing Mise."
echo -e "---"
curl https://mise.run | sh
echo -e "Bootstrapping."
echo -e "---"
mise trust && mise bootstrap --yes

exit 0
