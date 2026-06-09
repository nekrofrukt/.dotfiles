#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

eval "$(starship init bash)"
eval "$(fzf --bash)"
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="nvim"

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

alias la='ls -a'
alias ll='ls -lah'
alias tree='tree -a'

alias yin='yay -S'
alias yrm='yay -Rs'
alias yau='yay -Yc'

alias nv='nvim'
alias nvo='nvim -o `fzf --height 30% --layout reverse --preview '\''less {}'\''`'

#alias vault='opencode run --agent vault'

alias notes='cd ~/Dropbox/obsidian/home_vault/; yazi'

alias fetch='fastfetch --config ~/.config/fastfetch/mini.jsonc'
#fetch

alias sctl-health='systemctl --user list-units --type=service --all'
