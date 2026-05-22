
eval "$(starship init zsh)"
source <(fzf --zsh)
#not needed?
#eval "$(/opt/homebrew/bin/brew shellenv zsh)"

alias la='ls -a'
alias ll='ls -lah'

alias yup='brew update; brew upgrade'

alias nv='nvim'
alias nvo='nvim -o `fzf --height 30% --layout reverse --preview '\''less {}'\''`'

alias fetch='fastfetch --config ~/.config/fastfetch/mini.jsonc'
fetch
