sudo apt update
sudo apt upgrade
sudo apt-get install gh
sudo apt-get install git
sudo apt-get install nano

#!/bin/bash

# Update package list
echo "Updating package list..."
sudo apt update -y

# Install common utilities
echo "Installing common utilities..."
sudo apt install -y \
git \
gh \
nano \
vim \
curl \
wget \
htop \
tmux \
tree \
unzip \
net-tools \
ufw \
fail2ban \
zsh \
python3-pip \
jq \
lsb-release \
apt-transport-https \
ca-certificates \
gnupg \
software-properties-common \
