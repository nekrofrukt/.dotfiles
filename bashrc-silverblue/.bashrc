# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
eval "$(starship init bash)"
eval "$(fzf --bash)"

alias la='ls -a'
alias ll='ls -al'

alias la='ls -a'
alias ll='ls -lah'
alias tree='tree -a'

alias update='echo " "; echo "Updating Flatpak"; echo "----------------"; flatpak update; echo " "; echo " "; echo "Updating/upgrading Homebrew"; echo "---------------------------"; brew update; brew upgrade'

alias nv='nvim'
alias nvo='nvim -o `fzf --height 30% --layout reverse --preview '\''less {}'\''`'

alias oc='opencode'
alias mail='hey hey'

alias fetch='fastfetch --config ~/.config/fastfetch/mini.jsonc'
