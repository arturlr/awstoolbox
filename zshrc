#!/bin/zsh

#### OPTIONS ##################################################################
## https://zsh.sourceforge.io/Doc/Release/Options.html
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
unsetopt inc_append_history
unsetopt share_history

#### VARIABLES ################################################################

## NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

## Pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"

## Poetry
export PATH="$HOME/.poetry/bin:$PATH"
fpath+=~/.zfunc
autoload -Uz compinit && compinit

## Ruby
export PATH="$PATH:/opt/homebrew/opt/ruby/bin"
export LDFLAGS="-L/opt/homebrew/opt/ruby/lib"
export CPPFLAGS="-I/opt/homebrew/opt/ruby/include"

#### ALIASES ##################################################################
alias fd='find . -type d | sort'
alias ff='find . -type f | sort'
alias grep='grep --color=auto'
alias k9='kill -9'
alias ll='ls -lha'

alias pynew='pyenv virtualenv'
alias pyact='pyenv activate'
alias pydeact='pyenv deactivate'

#### FUNCTIONS ################################################################
function ts {
  iso_stamp=`date +"%Y-%m-%d %H:%M:%S"`
  echo $iso_stamp
}

function iso {
  iso_stamp=`date +"%Y-%m-%d"`
  echo $iso_stamp
}

function tmpname {
  local name=`date +"%Y-%m-%d_%H-%M-%S"`
  echo "tempfile_$name"
}

function bandwidth {
  echo "$(echo "en$(route get cachefly.cachefly.net | grep interface | sed -n -e 's/^.*en//p')") $(wget http://cachefly.cachefly.net/100mb.test -O /dev/null --report-speed=bits 2>&1 | grep '\([0-9.]\+ [KMG]b/s\)')"
}

#### OH MY ZSH ################################################################
export ZSH=$HOME/.oh-my-zsh  # Path to your oh-my-zsh installation.
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="yyyy-mm-dd"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#ZSH_THEME="robbyrussell"

# https://scottspence.com/posts/my-zsh-config
ZSH_THEME="spaceship"
export SPACESHIP_BATTERY_SHOW=false

plugins=(
  macos
  aws
  git
  pyenv
  docker
  history-substring-search
  zsh-syntax-highlighting
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

#### PATH #####################################################################
export PATH="$HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/local/opt/curl/bin:/usr/local/opt/ruby/bin:$HOME/.pyenv/shims/python:$PATH"
export LDFLAGS="-L/usr/local/opt/ruby/lib"
export CPPFLAGS="-I/usr/local/opt/ruby/include"
export PKG_CONFIG_PATH="/usr/local/opt/ruby/lib/pkgconfig"
export JAVA_TOOLS_OPTIONS="-Dlog4j2.formatMsgNoLookups=true"

# Added by Amplify CLI binary installer
export PATH="$HOME/.amplify/bin:$PATH"

# cfn-nag
export PATH="$HOME/.guard/bin:$PATH"
