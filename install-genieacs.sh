#!/bin/bash

# GenieACS Installer Script (Dokumentasi Resmi)
# Supports: Ubuntu 18.04, 20.04, 22.04

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

# 2. Install dependencies
echo "[+] Installing dependencies..."
sudo apt update
sudo apt install -y curl git build-essential redis-server \
  libcap2-bin ruby-full gnupg python3 g++ make

# 3. Install Node.js
echo "[+] Installing Node.js..."
if [[ "$OS_VER" == "18.04" ]]; then
  curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
else
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
fi
sudo apt install -y nodejs

# 4. Install MongoDB 4.4
echo "[+] Installing MongoDB 4.4..."
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
if [[ "$OS_VER" == "18.04" ]]; then
  echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
elif [[ "$OS_VER" == "20.04" ]]; then
  echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
else
  echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
fi
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl enable mongod
sudo systemctl start mongod

# 5. Install GenieACS globally
echo "[+] Installing GenieACS..."
sudo npm install -g genieacs@1.2.13

# 6. Create genieacs user and directories
echo "[+] Creating genieacs user and directories..."
sudo useradd --system --no-create-home --user-group genieacs
sudo mkdir -p /opt/genieacs/ext
sudo chown -R genieacs:genieacs /opt/genieacs/ext

# 7. Create environment config
echo "[+] Creating environment config..."
cat <<EOF | sudo tee /opt/genieacs/genieacs.env
GENIEACS_CWMP_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-cwmp-access.log
GENIEACS_NBI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-nbi-access.log
GENIEACS_FS_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-fs-access.log
GENIEACS_UI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-ui-access.log
GENIEACS_DEBUG_FILE=/var/log/genieacs/genieacs-debug.yaml
NODE_OPTIONS=--enable-source-maps
GENIEACS_EXT_DIR=/opt/genieacs/ext
EOF

# Tambahkan JWT secret
echo "[+] Generating JWT secret..."
node -e "console.log('GENIEACS_UI_JWT_SECRET=' + require('crypto').randomBytes(128).toString('hex'))" | sudo tee -a /opt/genieacs/genieacs.env
sudo chown genieacs:genieacs /opt/genieacs/genieacs.env
sudo chmod 600 /opt/genieacs/genieacs.env

# 8. Create log directory
echo "[+] Creating log directory..."
sudo mkdir -p /var/log/genieacs
sudo chown genieacs:genieacs /var/log/genieacs

# 9. Create systemd service files
echo "[+] Creating systemd unit files..."
for svc in cwmp nbi fs ui; do
sudo tee /etc/systemd/system/genieacs-$svc.service > /dev/null <<EOF
[Unit]
Description=GenieACS $svc
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-$svc

[Install]
WantedBy=multi-user.target
EOF
done

# 10. Setup logrotate
echo "[+] Setting up logrotate..."
cat <<EOF | sudo tee /etc/logrotate.d/genieacs
/var/log/genieacs/*.log /var/log/genieacs/*.yaml {
    daily
    rotate 30
    compress
    delaycompress
    dateext
}
EOF

# 11. Enable and start services
echo "[+] Enabling and starting GenieACS services..."
sudo systemctl daemon-reload
for svc in cwmp nbi fs ui; do
  sudo systemctl enable genieacs-$svc
  sudo systemctl start genieacs-$svc
done

# 12. Done
echo "======================================="
echo "[✓] GenieACS installed successfully!"
echo "    UI:  http://<server-ip>:3000"
echo "======================================="
