#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

eval "$(starship init bash)"
eval "$(fzf --bash)"
export PATH="$HOME/.local/bin:$PATH"

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

alias la='ls -a'
alias ll='ls -la'
alias tree='tree -a'

alias yup='yay -Syu'
alias yin='yay -S'
alias yrm='yay -Rs'
alias yau='yay -Yc'

alias nv='nvim'
alias nvo='nvim -o `fzf --height 30% --layout reverse --preview '\''less {}'\''`'

alias fetch='fastfetch --config ~/.config/fastfetch/mini.jsonc'
#fetch
