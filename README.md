# ubuntu-server
base for davidlan ubuntu server


```bash

# Install unzip if not already installed
cd ~/
sudo apt-get update && sudo apt-get install -y unzip

# Create the target directory for the repo
mkdir -p ~/ubuntu-server
cd ~/ubuntu-server

# Download the repository as a ZIP file
curl -L -o ubuntu-server.zip https://github.com/davviie/ubuntu-server/archive/refs/heads/main.zip
ls -lh ubuntu-server.zip

# Verify the ZIP file was downloaded successfully
if [ -f "ubuntu-server.zip" ]; then
    # Unpack the ZIP file into the current directory
    unzip ubuntu-server.zip
    mv ubuntu-server-main/* .
    mv ubuntu-server-main/.* . 2>/dev/null || true  # Move hidden files as well
    rmdir ubuntu-server-main

    # Clean up the ZIP file
    rm ubuntu-server.zip

    echo "Repository downloaded and unpacked into ~/ubuntu-server"
else
    echo "Failed to download the ZIP file. Please check your internet connection or the link."
fi

```

