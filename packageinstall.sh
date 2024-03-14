#!/bin/bash
sudo apt update -y
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt install python3.10 -y

pip3 install --upgrade pip
pip3 install arrow
pip3 install torch torchvision torchtext
pip3 install numpy
pip3 install wandb
pip3 install torchdata
pip3 install scipy
pip3 install scikit-learn
pip3 install requests
pip3 install transformers
pip3 install datasets
pip3 install loralib
