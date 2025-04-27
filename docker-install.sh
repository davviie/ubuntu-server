#!/bin/bash

# Function to handle errors and log them
log_error() {
    echo "[ERROR] $1" | tee -a docker_install_debug.log
}

# Update and install prerequisites
sudo apt-get update || log_error "Failed to update package database."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    gnupg \
    lsb-release \
    uidmap || log_error "Failed to install prerequisites."

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg || log_error "Failed to add Docker's GPG key."

# Set up the stable Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || log_error "Failed to set up Docker repository."

# Update the package database
sudo apt-get update || log_error "Failed to update package database after adding Docker repository."

# Install Docker components
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || log_error "Failed to install Docker components."

# Configure Docker for rootless mode
sudo apt-get install -y uidmap || log_error "Failed to install uidmap for rootless mode."
dockerd-rootless-setuptool.sh install || log_error "Failed to configure Docker rootless mode."

# Add the current user to the "docker" group
sudo usermod -aG docker $USER || log_error "Failed to add user to the Docker group."

# Reload group changes
newgrp docker || log_error "Failed to reload group changes for Docker group."

# Configure Docker to store data in ~/docker
mkdir -p ~/docker || log_error "Failed to create ~/docker directory."
echo '{
    "data-root": "~/docker"
}' | sudo tee /etc/docker/daemon.json > /dev/null || log_error "Failed to configure Docker's data-root to ~/docker."

# Restart Docker to apply changes
sudo systemctl restart docker || log_error "Failed to restart Docker service."

# Validate the installation
if ! docker run hello-world; then
    log_error "Docker validation failed. Please check the installation."
else
    echo "Docker installation completed successfully!"
fi
