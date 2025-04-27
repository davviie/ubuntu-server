#!/bin/bash

# Function to handle errors and log them
log_error() {
    echo "[ERROR] $1" | tee -a docker_install_debug.log
    exit 1
}

# Function to print status with colors
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "\e[32m[PASS]\e[0m $2"
    else
        echo -e "\e[31m[FAIL]\e[0m $2"
        log_error "$2"
    fi
}

# Function to check if Docker is already configured for rootless mode
check_rootless_mode() {
    if [[ -S $XDG_RUNTIME_DIR/docker.sock ]]; then
        echo -e "\e[33m[SKIP]\e[0m Docker is already configured for rootless mode."
        return 0
    fi

    if [[ -S /var/run/docker.sock ]]; then
        echo -e "\e[31m[ERROR]\e[0m Rootful Docker (/var/run/docker.sock) is running and accessible."
        log_error "Aborting because rootful Docker is running. Use --force to ignore."
    fi

    return 1
}

# Update and install prerequisites
echo "Updating package database and installing prerequisites..."
sudo apt-get update || log_error "Failed to update package database."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    gnupg \
    lsb-release \
    uidmap || log_error "Failed to install prerequisites."
print_status $? "Prerequisites installed successfully."

# Add Docker's official GPG key
echo "Adding Docker's GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg || log_error "Failed to add Docker's GPG key."
print_status $? "Docker's GPG key added successfully."

# Set up the stable Docker repository
echo "Setting up the stable Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || log_error "Failed to set up Docker repository."
sudo apt-get update || log_error "Failed to update package database after adding Docker repository."
print_status $? "Docker repository set up successfully."

# Install Docker components
echo "Installing Docker components..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || log_error "Failed to install Docker components."
print_status $? "Docker components installed successfully."

# Check and configure Docker for rootless mode
echo "Configuring Docker for rootless mode..."
check_rootless_mode
if [ $? -eq 1 ]; then
    dockerd-rootless-setuptool.sh install || log_error "Failed to configure Docker in rootless mode."
    print_status $? "Docker configured for rootless mode."

    # Export DOCKER_HOST for the current session
    export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock

    # Persist DOCKER_HOST in shell configuration
    if ! grep -q "export DOCKER_HOST=unix://\$XDG_RUNTIME_DIR/docker.sock" ~/.bashrc; then
        echo 'export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock' >> ~/.bashrc
        echo "DOCKER_HOST variable has been added to ~/.bashrc for persistence."
    fi

    # Reload shell configuration
    source ~/.bashrc || log_error "Failed to reload shell configuration."
fi

# Add the current user to the "docker" group
echo "Adding the current user to the 'docker' group..."
sudo usermod -aG docker $USER || log_error "Failed to add user to the Docker group."
newgrp docker || log_error "Failed to reload group changes for Docker group."
print_status $? "User added to the Docker group successfully."

# Configure Docker to store data in ~/docker
echo "Configuring Docker to store data in ~/docker..."
mkdir -p ~/docker || log_error "Failed to create ~/docker directory."
echo '{
    "data-root": "~/docker"
}' | sudo tee /etc/docker/daemon.json > /dev/null || log_error "Failed to configure Docker's data-root to ~/docker."
sudo systemctl restart docker || log_error "Failed to restart Docker service."
print_status $? "Docker data-root configured and service restarted."

# Step 1: Check if docker.service is active
echo "Checking if Docker service is active..."
systemctl --user is-active docker.service > /dev/null 2>&1
print_status $? "Docker service is active."

# Step 2: Run 'docker info'
echo "Running 'docker info' to verify Docker is functioning..."
docker info > /dev/null 2>&1
print_status $? "'docker info' command executed successfully."

# Step 3: Run the 'hello-world' container test
echo "Running the 'hello-world' container test..."
docker run --rm hello-world > /dev/null 2>&1
print_status $? "'hello-world' container test passed."

# Final Message
echo -e "\e[32mDocker installation and validation completed successfully!\e[0m"
