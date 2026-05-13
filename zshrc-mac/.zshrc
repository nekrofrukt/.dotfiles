
eval "$(starship init zsh)"
source <(fzf --zsh)
#eval "$(/opt/homebrew/bin/brew shellenv zsh)"

alias la='ls -a'
alias ll='ls -la'

alias nv='nvim'
alias nvo='nvim -o `fzf --height 30% --layout reverse --preview '\''less {}'\''`'
