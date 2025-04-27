#!/bin/bash

# Filepath: setup-git-gh.sh

# Check and install Git if not installed
if ! command -v git &> /dev/null; then
    echo "Git is not installed. Installing Git..."
    sudo apt-get update
    sudo apt-get install -y git
    echo "Git has been installed successfully."
else
    echo "Git is already installed."
fi

# Check and install GitHub CLI (gh) if not installed
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI (gh) is not installed. Installing GitHub CLI..."
    sudo apt-get update
    sudo apt-get install -y gh
    echo "GitHub CLI has been installed successfully."
else
    echo "GitHub CLI is already installed."
fi

# Prompt for GitHub authentication
echo "Logging into GitHub..."
gh auth login

# Prompt for global Git configuration
echo "Setting up global Git configuration..."
read -p "Enter your global Git username: " global_username
read -p "Enter your global Git email: " global_email

# Validate email format
if [[ ! "$global_email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "Error: Invalid email format. Please try again."
    exit 1
fi

# Apply global Git configuration
if git config --global user.name &> /dev/null || git config --global user.email &> /dev/null; then
    echo "Warning: Global Git configuration already exists."
    read -p "Do you want to overwrite it? (y/n): " overwrite_global
    if [[ "$overwrite_global" != "y" && "$overwrite_global" != "Y" ]]; then
        echo "Skipping global Git configuration..."
    else
        git config --global user.name "$global_username"
        git config --global user.email "$global_email"
    fi
else
    git config --global user.name "$global_username"
    git config --global user.email "$global_email"
fi

# Ensure default branch name is set to "main"
git config --global init.defaultBranch main
echo "Default Git branch set to 'main'."

# Prompt for local Git configuration (optional)
read -p "Do you want to set local Git configuration for this repository? (y/n): " set_local
if [[ "$set_local" == "y" || "$set_local" == "Y" ]]; then
    read -p "Do you want to use the global Git configuration for this repository? (y/n): " use_global
    if [[ "$use_global" == "y" || "$use_global" == "Y" ]]; then
        # Use global Git configuration for local
        global_username=$(git config --global user.name)
        global_email=$(git config --global user.email)
        git config user.name "$global_username"
        git config user.email "$global_email"
        echo "Local Git configuration set to use global settings: $global_username <$global_email>"
    else
        # Prompt for custom local Git configuration
        read -p "Enter your local Git username: " local_username
        read -p "Enter your local Git email: " local_email
        git config user.name "$local_username"
        git config user.email "$local_email"
        echo "Custom local Git configuration set: $local_username <$local_email>"
    fi
fi

# Prompt to add an SSH key for GitHub (optional)
read -p "Do you want to generate and add an SSH key for GitHub? (y/n): " add_ssh
if [[ "$add_ssh" == "y" || "$add_ssh" == "Y" ]]; then
    ssh-keygen -t rsa -b 4096 -C "$global_email"
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_rsa
    gh ssh-key add ~/.ssh/id_rsa.pub --title "GitHub SSH Key"
    echo "SSH key added to GitHub successfully."
fi

# Display the current Git configuration
echo "Current Git configuration:"
git config --list

echo "Setup complete!"
