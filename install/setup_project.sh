#!/bin/bash

set -e

HOME="/home/pi"
DRONE_DIR="$HOME/drone-rpi3-32-bit"
INSTALL_DIR="$DRONE_DIR/install"
LOG_DIR="$INSTALL_DIR/logs"

if [ ! -d "$LOG_DIR" ]; then 
  mkdir -p $LOG_DIR 
fi

BUILD_LOG="$LOG_DIR/setup_opennisdk.log"
exec > >(tee "$BUILD_LOG") 2>&1

# Step 1: update system packages
echo "[1/3] Project: update system packages..."
sudo apt update && sudo apt dist-upgrade

# Step 2: install system packages
echo "[2/3] Project: installing system packages..."
sudo apt -y install python3-opencv python3-venv

# Step 3: creating virtual environment and install packages
echo "[3/3] Project: creating virtual environment and installing packages..."
cd "$DRONE_DIR"
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt

echo "✅ project setup successfully"
exit 0