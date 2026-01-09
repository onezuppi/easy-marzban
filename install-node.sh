#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Update packages
apt-get update
apt-get upgrade -y
apt-get install curl socat git -y

# Install Docker from repository
curl -fsSL https://raw.githubusercontent.com/onezuppi/install-docker-sh/refs/heads/main/install.sh \
  | bash

# Check if node folder exists
if [ -d "node" ]; then
  echo "Node folder found, using existing one."
else
  echo "Node folder not found, cloning repository..."
  git clone https://github.com/onezuppi/easy-marzban.git temp_repo
  if [ -d "temp_repo/node" ]; then
    mv temp_repo/node .
    rm -rf temp_repo
    echo "Node folder successfully copied from repository."
  else
    echo "Error: Node folder not found in repository."
    rm -rf temp_repo
    exit 1
  fi
fi

# Change to node directory
cd node

# Create .env file with user input
if [ -f ".env" ]; then
  echo ".env file already exists. Overwrite? (y/n)"
  read -r overwrite
  if [ "$overwrite" != "y" ] && [ "$overwrite" != "Y" ]; then
    echo "Using existing .env file."
    SKIP_ENV=true
  else
    SKIP_ENV=false
  fi
else
  SKIP_ENV=false
fi

if [ "$SKIP_ENV" = false ]; then
  # Request EMAIL from user
  echo "Enter EMAIL:"
  read -r EMAIL

  # Request DOMAIN from user
  echo "Enter DOMAIN:"
  read -r DOMAIN

  # Create .env file
  cat > .env << EOF
EMAIL=${EMAIL}
DOMAIN=${DOMAIN}
EOF

  echo ".env file successfully created with EMAIL and DOMAIN variables."
fi

# Request SSL certificate from user
echo "Enter SSL client certificate (paste the full certificate including BEGIN and END lines, then type 'CERT_END' on a new line and press Enter to finish):"
> ssl_client_cert.pem
while IFS= read -r line; do
  if [ "$line" = "CERT_END" ]; then
    break
  fi
  echo "$line" >> marzban-node/ssl_client_cert.pem
done

echo "SSL client certificate saved to ssl_client_cert.pem."

# Start containers
docker compose up -d