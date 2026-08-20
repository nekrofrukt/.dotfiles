#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

eval "$(starship init bash)"
eval "$(fzf --bash)"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"

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

alias xi='sudo xbps-install'
alias xq='xbps-query'
alias xr='sudo xbps-remove'
alias xu-src='~/.dotfiles/scripts/void/xbps/update-xbps-src'
alias fu='flatpak update'

alias shutdown='loginctl poweroff'
alias reboot='loginctl reboot'
alias suspend='loginctl suspend'

alias nv='nvim'
alias nvo='nvim -o `fzf --height 30% --layout reverse --preview '\''less {}'\''`'

alias fetch='fastfetch --config ~/.config/fastfetch/mini.jsonc'
