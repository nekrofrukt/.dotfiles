#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

eval "$(starship init bash)"
export PATH="$HOME/.local/bin:$PATH"

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# Start ssh-agent, from Arch wiki
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent -t 4h > "$XDG_RUNTIME_DIR/ssh-agent.env"
fi
if [ ! -f "$SSH_AUTH_SOCK" ]; then
    source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
fi

alias la='ls -a'
alias ll='ls -la'
alias tree='tree -a'

alias yup='yay -Syu'
alias yin='yay -S'
alias yrm='yay -Rs'
alias yau='yay -Yc'

alias fetch='fastfetch --config ~/.config/fastfetch/mini.jsonc'
fetch
