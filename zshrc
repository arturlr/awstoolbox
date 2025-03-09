# Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"
#!/bin/zsh

#### OPTIONS ##################################################################
## https://zsh.sourceforge.io/Doc/Release/Options.html
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
unsetopt inc_append_history
unsetopt share_history

#### ALIASES ##################################################################
alias fd='find . -type d | sort'
alias ff='find . -type f | sort'
alias grep='grep --color=auto'
alias k9='kill -9'
alias ll='ls -lha'

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
#COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="yyyy-mm-dd"

ZSH_THEME=""

plugins=(
  history-substring-search
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

#### PATH #####################################################################
export PATH="$HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/local/opt/curl/bin:/usr/local/opt/ruby/bin"
export LDFLAGS="-L/usr/local/opt/ruby/lib"
export CPPFLAGS="-I/usr/local/opt/ruby/include"
export PKG_CONFIG_PATH="/usr/local/opt/ruby/lib/pkgconfig"

## Java
export JAVA_TOOLS_OPTIONS="-Dlog4j2.formatMsgNoLookups=true"
export JAVA_HOME=/Library/Java/JavaVirtualMachines/amazon-corretto-8.jdk/Contents/Home
export M2_HOME="/usr/local/bin/apache-maven-3.9.9"
PATH="${M2_HOME}/bin:${PATH}"

# Added by Amplify CLI binary installer
export PATH="$HOME/.amplify/bin:$PATH"

# cfn-nag
export PATH="$HOME/.guard/bin:$PATH"

eval "$(starship init zsh)"

#### MISE #####################################################################
# you typically want to put mise activate at the end of your shell config so nothing overrides it.
eval "$(~/.local/bin/mise activate zsh)"

# Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"
