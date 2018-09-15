if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

eval $(dircolors -b)

# User specific aliases and functions
alias ..='cd ..'
alias ...='cd ../..'
alias cls='tput reset'
alias dir='ls --color=auto -l'
alias ll='ls --color=auto -l'
alias la='ls --color=auto -la'
alias l='ls --color=auto -alF'
alias ls='ls --color=auto'
alias rm='rm -I'
alias cp='cp -i'
