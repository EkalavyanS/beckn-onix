#!/bin/bash

# Install dependencies using snap where possible
install_dependencies_linux() {
    # Update package list and install curl
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl

    # Install snap if it's not installed
    if ! command -v snap &> /dev/null; then
        echo "Snap is not installed. Installing snap..."
        sudo apt-get install -y snapd
    fi

    # Install Docker using snap
    echo "Installing Docker..."
    sudo snap install docker

    # Ensure Docker is started and enabled
    sudo systemctl enable --now snap.docker.dockerd

    # Install Docker Compose
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    echo "Installing Node.js and NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    source ~/.bashrc
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    nvm install 20
    npm i -g localtunnel

    # Add user to the docker group and apply permissions
    sudo groupadd docker
    sudo usermod -aG docker $USER
    newgrp docker
}

install_dependencies_mac() {
    brew install curl
    brew install gpg

    # Install Docker using brew
    echo "Installing Docker..."
    brew install --cask docker
    open /Applications/Docker.app

    # Install Docker Compose
    echo "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    echo "Installing Node.js and NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    nvm install 20
    npm i -g localtunnel

    # Add user to the docker group and apply permissions
    sudo dscl . create /Groups/docker
    sudo dscl . append /Groups/docker GroupMembership $(whoami)
}

if [[ $(uname) == 'Linux' ]]; then
    install_dependencies_linux
elif [[ $(uname) == 'Darwin' ]]; then
    install_dependencies_mac
else
    echo "Unsupported operating system."
    exit 1
fi

# Set script variables
PROJECT_DIR="GUI"
PORT=3005
TUNNEL_SERVICE="lt"

# Change to the project directory
cd "$PROJECT_DIR" || exit
nvm use 20
npm i

# Build and start the Next.js app
echo "Installing dependencies..."
echo "Building and starting Next.js app..."
pkill node
pkill geniuslm
npx next build
echo "Building Web App = True"
sleep 3
npx next start -p "$PORT" &

# Wait for the Next.js app to start
sleep 3

# Install the tunnel service if not installed
echo "Exposing local port $PORT using $TUNNEL_SERVICE..."
lt --port "$PORT" > /tmp/lt.log 2>&1 &

# Wait for the tunnel service to start
echo "Waiting for tunnel service to start..."
sleep 5

# Get the tunnel URL from the log file
TUNNEL_URL=$(grep -o 'https://[^[:blank:]]*' /tmp/lt.log)

# Get the tunnel password
echo "Getting Tunnel Password"
TUNNEL_PASSWORD=$(curl https://loca.lt/mytunnelpassword)

# Print the tunnel URL and password
echo "---------------------------------------"
echo "Next.js app is running locally on port $PORT"
echo "Tunnel Service URL: $TUNNEL_URL"
echo "Tunnel Password: $TUNNEL_PASSWORD"
echo "---------------------------------------"
