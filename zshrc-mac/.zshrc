
eval "$(starship init zsh)"
source <(fzf --zsh)
#set -o vi
#eval "$(/opt/homebrew/bin/brew shellenv zsh)"

# Fabric
# Golang environment variables
export GOROOT=$(brew --prefix go)/libexec
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$HOME/.local/bin:$PATH

alias la='ls -a'
alias ll='ls -lah'

alias bup='brew update; brew upgrade'

alias nv='nvim'
alias nvo='nvim -o `fzf --height 30% --layout reverse --preview '\''less {}'\''`'

alias fetch='fastfetch --config ~/.config/fastfetch/mini.jsonc'
#fetch

alias fabric='fabric-ai'
