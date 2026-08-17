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
eval $(keychain --eval --noask id_ed25519)

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

alias xu='sudo vuru update'
alias xi='sudo xbps-install'
alias xs='xbps-query -Rs'
alias xr='sudo xbps-remove'
alias xa='sudo xbps-remove -o'

alias shutdown='loginctl poweroff'
alias reboot='loginctl reboot'
alias suspend='loginctl suspend'

alias nv='nvim'
alias nvo='nvim -o `fzf --height 30% --layout reverse --preview '\''less {}'\''`'

alias fetch='fastfetch --config ~/.config/fastfetch/mini.jsonc'
