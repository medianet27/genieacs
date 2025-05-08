#!/bin/bash

# Instalasi otomatis GenieACS (tanpa Docker)
# Tested on Ubuntu 20.04/22.04

set -e

echo "[+] Update system & install dependencies..."
sudo apt update && sudo apt install -y \
  git curl build-essential redis-server \
  mongodb nodejs npm libcap2-bin ruby-full

echo "[+] Setting up Node.js v18 LTS..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

echo "[+] Cloning GenieACS..."
cd /opt
sudo git clone https://github.com/genieacs/genieacs.git
cd genieacs
sudo npm install

echo "[+] Creating GenieACS systemd services..."
sudo tee /etc/systemd/system/genieacs-cwmp.service > /dev/null <<EOF
[Unit]
Description=GenieACS CWMP
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/npm run start-cwmp
WorkingDirectory=/opt/genieacs
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/genieacs-nbi.service > /dev/null <<EOF
[Unit]
Description=GenieACS NBI
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/npm run start-nbi
WorkingDirectory=/opt/genieacs
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/genieacs-fs.service > /dev/null <<EOF
[Unit]
Description=GenieACS FS
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/npm run start-fs
WorkingDirectory=/opt/genieacs
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

echo "[+] Enabling and starting GenieACS services..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable genieacs-cwmp genieacs-nbi genieacs-fs
sudo systemctl start genieacs-cwmp genieacs-nbi genieacs-fs

echo "[+] GenieACS Installed successfully!"
