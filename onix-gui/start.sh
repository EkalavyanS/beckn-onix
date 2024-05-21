#!/bin/bash

# Function to install dependencies on Linux
install_dependencies_linux() {
    # Detect the package manager
    if command -v apt-get &>/dev/null; then
        PACKAGE_MANAGER="apt-get"
    elif command -v yum &>/dev/null; then
        PACKAGE_MANAGER="yum"
    elif command -v dnf &>/dev/null; then
        PACKAGE_MANAGER="dnf"
    elif command -v pacman &>/dev/null; then
        PACKAGE_MANAGER="pacman"
    else
        echo "Unsupported package manager."
        exit 1
    fi

    # Install Snap if not installed
    if ! command -v snap &>/dev/null; then
        echo "Snap is not installed. Installing snap..."
        case $PACKAGE_MANAGER in
            apt-get)
                sudo apt-get update
                sudo apt-get install -y snapd
                ;;
            yum)
                sudo yum install -y epel-release
                sudo yum install -y snapd
                ;;
            dnf)
                sudo dnf install -y snapd
                ;;
            pacman)
                sudo pacman -Sy snapd
                sudo systemctl enable --now snapd.socket
                sudo ln -s /var/lib/snapd/snap /snap
                ;;
        esac
        sudo systemctl enable --now snapd.socket
    fi

    # Install Docker
    echo "Installing Docker..."
    sudo snap install docker

    # Install Docker Compose
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    # Install Node.js and NVM
    echo "Installing Node.js and NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    nvm install 20
    npm install -g localtunnel

    # Add user to the docker group and apply permissions
    sudo groupadd docker
    sudo usermod -aG docker $USER
    newgrp docker
}

# Function to install dependencies on Mac
install_dependencies_mac() {
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew install curl gpg
    brew install --cask docker
    brew install docker-compose
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    nvm install 20
    npm install -g localtunnel
}

# Detect operating system and install dependencies
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
npm install

# Build and start the Next.js app
echo "Installing Dependencies"
echo "Building and starting Next.js app..."
pkill node
pkill geniuslm
npx next build
echo "Building Web App = True"
sleep 3
npx next start -p "$PORT" &

# Wait for the Next.js app to start
sleep 3
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
