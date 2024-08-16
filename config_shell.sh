#!/bin/bash

# installing zsh and git
sudo yum install zsh git

# installing spaceship for zsh
git clone https://github.com/spaceship-prompt/spaceship-prompt $HOME/.zsh/spaceship

# install oh my zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash

# pyenv install
curl https://pyenv.run | bash

# aws cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# dotnet install
wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
chmod +x ./dotnet-install.sh
./dotnet-install.sh --version latest
./dotnet-install.sh --channel 3.1
