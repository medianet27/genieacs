#!/bin/bash

set -e

echo "==============================================="
echo " GenieACS Partial Restore from GitHub"
echo "==============================================="

# Ganti URL ini sesuai lokasi file backup kamu di GitHub
BACKUP_URL="https://raw.githubusercontent.com/medianet27/genieacs/main/genieacs-partial-backup.tar.gz"

# 1. Unduh file
echo "[+] Downloading backup..."
cd /tmp
wget -q -O genieacs-backup.tar.gz "$BACKUP_URL"

# 2. Ekstrak
echo "[+] Extracting backup..."
tar -xzf genieacs-backup.tar.gz

# 3. Hapus koleksi lama dulu
echo "[+] Dropping existing collections..."
mongo genieacs --quiet --eval '
  db.presets.drop();
  db.provisions.drop();
  db.virtualParameters.drop();
  db.config.drop();
  db.permissions.drop();
  db.users.drop();
'

# 4. Restore hanya koleksi penting
echo "[+] Restoring collections..."
mongorestore --quiet --db genieacs /tmp/genieacs-partial-backup/genieacs

# 5. Bersih-bersih
rm -rf /tmp/genieacs-backup*

echo "==============================================="
echo "[✓] Restore selesai! GenieACS config dipulihkan."
echo "==============================================="
