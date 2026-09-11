#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"

eval "$(mise activate bash)"
eval "$(starship init bash)"
eval "$(fzf --bash)"

# SSH agent via keychain
eval $(keychain -q --eval --noask id_ed25519)

# Tab completion
if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
fi

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

alias la='ls -a'
alias ll='ls -lah'
alias tree='tree -a'

alias lnk='sudo ln -s'
alias purge-kernels='sudo vkpurge rm all'

alias xi='sudo xbps-install'
alias xq='xbps-query'
alias xr='sudo xbps-remove'
alias xu-src='~/.dotfiles/scripts/void/xbps/update-xbps-src'
alias update-system='echo " "; echo "Syncing remote repo index and updating all packages."; echo "---"; sudo xbps-install -Su; echo " "; echo "Updating local xbps-src repo."; echo "---"; ~/.dotfiles/scripts/void/xbps/update-xbps-src; echo " "; echo "Updating Mise and Flatpak."; echo "---"; mise upgrade; mise prune; mise bootstrap packages apply --yes'
alias xm-upgrade='mise upgrade; mise prune; mise bootstrap packages apply --yes; echo "---"; flatpak update'

alias shutdown='loginctl poweroff'
alias reboot='loginctl reboot'
alias suspend='loginctl suspend'

alias nv='nvim'
alias nvo='nvim -o `fzf --height 30% --layout reverse --preview '\''less {}'\''`'

alias oc='opencode'

alias fetch='fastfetch --config ~/.config/fastfetch/mini.jsonc'
