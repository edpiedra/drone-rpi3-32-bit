#!/bin/bash

set -euo pipefail

HOME="/home/pi"
DRONE_DIR="$HOME/drone-rpi3-32-bit"
LOG_DIR="$DRONE_DIR/install/logs"
BUILD_LOG="$LOG_DIR/setup_project.log"

mkdir -p "$LOG_DIR"
exec > >(tee "$BUILD_LOG") 2>&1

log() { echo -e "\n[INFO] $1\n"; }

log "[1/3] Updating system packages..."
sudo apt update && sudo apt -y dist-upgrade

log "[2/3] Installing required packages..."
sudo apt install -y python3-opencv python3-venv

log "[3/3] Setting up Python virtual environment..."
cd "$DRONE_DIR"
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

log "✅ Project setup complete. Logs saved to: $BUILD_LOG"
exit 0
