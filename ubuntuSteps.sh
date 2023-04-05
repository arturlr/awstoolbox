# Install packages
sudo apt install build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev zip zsh

# Shell config (Zsh and Oh my Zsh)
curl -sS https://starship.rs/install.sh | sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# PyEnc
curl https://pyenv.run | bash
# NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash 

# AWS CLI and SAM
wget https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
wget https://github.com/aws/aws-sam-cli/releases/download/v1.78.0/aws-sam-cli-linux-x86_64.zip

# Docker
https://docs.docker.com/engine/install/ubuntu/ 

add ubuntu to as a user to the docker group (/etc/group). Logout.
