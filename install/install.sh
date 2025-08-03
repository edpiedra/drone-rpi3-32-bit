#!/bin/bash

set -euo pipefail

HOME="/home/pi"
INSTALL_DIR="$HOME/drone-rpi3-32-bit/install"
LOG_DIR="$INSTALL_DIR/logs"
OPENNISDK_INSTALL="$INSTALL_DIR/setup_opennisdk.sh"
PROJECT_INSTALL="$INSTALL_DIR/setup_project.sh"
BUILD_LOG="$LOG_DIR/install.log"

mkdir -p "$LOG_DIR"
exec > >(tee "$BUILD_LOG") 2>&1

log() { echo -e "\n[INFO] $1\n"; }

log "[1/2] Installing OpenNI SDK..."
chmod +x "$OPENNISDK_INSTALL"
sudo "$OPENNISDK_INSTALL"

log "[2/2] Installing project dependencies..."
chmod +x "$PROJECT_INSTALL"
sudo "$PROJECT_INSTALL"

log "✅ Setup complete. Logs saved to: $BUILD_LOG"
exit 0