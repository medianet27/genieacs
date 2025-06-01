#!/bin/bash

# GenieACS Installer Script (Updated)
# Supports: Ubuntu 18.04, 20.04, 22.04
# Author: ChatGPT - OpenAI

set -e

echo "======================================="
echo " GenieACS Installer for Ubuntu"
echo " Supported: 18.04, 20.04, 22.04"
echo "======================================="

# 1. Detect OS version
source /etc/os-release
OS_VER=$VERSION_ID
echo "[+] Detected Ubuntu $OS_VER"

if [[ "$OS_VER" != "18.04" && "$OS_VER" != "20.04" && "$OS_VER" != "22.04" ]]; then
  echo "[-] Unsupported OS version: $OS_VER"
  exit 1
fi

# 2. Update system and install core packages
echo "[+] Updating system and installing base packages..."
sudo apt update
sudo apt install -y curl git build-essential redis-server \
  libcap2-bin ruby-full gnupg python3 g++ make

# 3. Install Node.js v18.x from NodeSource
echo "[+] Installing Node.js v18.x..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# 4. Install MongoDB based on OS version
echo "[+] Installing MongoDB..."
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -

if [[ "$OS_VER" == "18.04" ]]; then
  echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
elif [[ "$OS_VER" == "20.04" ]]; then
  echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
elif [[ "$OS_VER" == "22.04" ]]; then
  echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
fi

sudo apt update
sudo apt install -y mongodb-org
sudo systemctl enable mongod
sudo systemctl start mongod

# 5. Clone GenieACS repository
echo "[+] Cloning GenieACS..."
cd /opt
sudo git clone https://github.com/genieacs/genieacs.git
cd genieacs
sudo npm install

# 6. Create systemd service files
echo "[+] Creating systemd service files..."

for svc in cwmp nbi fs; do
sudo tee /etc/systemd/system/genieacs-$svc.service > /dev/null <<EOF
[Unit]
Description=GenieACS $svc
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/npm run start-$svc
WorkingDirectory=/opt/genieacs
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
done

# 7. Enable and start services
echo "[+] Enabling and starting GenieACS services..."
sudo systemctl daemon-reload
sudo systemctl enable genieacs-cwmp genieacs-nbi genieacs-fs
sudo systemctl start genieacs-cwmp genieacs-nbi genieacs-fs

# 8. Done
echo "======================================="
echo "[✓] GenieACS installed successfully!"
echo "    Access NBI at http://<server-ip>:7557"
echo "======================================="
