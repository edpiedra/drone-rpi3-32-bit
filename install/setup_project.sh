#!/bin/bash

set -euo pipefail

HOME="/home/pi"
DRONE_DIR="$HOME/drone-rpi3-32-bit"
LOG_DIR="$DRONE_DIR/install/logs"
BUILD_LOG="$LOG_DIR/setup_project.log"
NAVIO2_GIT="https://github.com/emlid/Navio2.git"
NAVIO2_DIR="$HOME/Navio2"
NAVIO2_PYTHON_DIR="$NAVIO2_DIR/Python"

mkdir -p "$LOG_DIR"
exec > >(tee "$BUILD_LOG") 2>&1

log() { echo -e "\n[INFO] $1\n"; }

log "[1/4] Updating system packages..."
sudo apt update && sudo apt -y dist-upgrade

log "[2/4] Installing required packages..."
sudo apt install -y python3-opencv python3-venv

log "[3/4] Cloning from $NAVIO2_GIT ..."
cd "$HOME"

if [ -d "$NAVIO2_DIR" ]; then 
    rm -r "$NAVIO2_DIR"
fi 

sudo git clone "$NAVIO2_GIT"
cd "$NAVIO2_PYTHON_DIR"
sudo apt install -y python3-smbus python3-spidev
python3 -m venv env --system-site-packages
source env/bin/activate
python3 -m pip install wheel
python3 setup.py bdist_wheel

log "[4/4] Setting up Python virtual environment for drone project..."
cd "$DRONE_DIR"
sudo apt install -y python3-numpy

if [ ! -d .venv ]; then 
    sudo python3 -m venv .venv --system-site-packages
fi
source .venv/bin/activate
sudo python3 -m pip install "$NAVIO2_PYTHON_DIR/dist/navio2-1.0.0-py3-none-any.whl"
sudo python3 -m pip install -r requirements.txt

log "✅ Project setup complete. Logs saved to: $BUILD_LOG"
exit 0
