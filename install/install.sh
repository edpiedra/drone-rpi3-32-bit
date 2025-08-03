#!/bin/bash

set -e

HOME="/home/pi"

# configuration
INSTALL_DIR="$HOME/drone-rpi3-32-bit/install"
OPENNISDK_INSTALL="$INSTALL_DIR/setup_opennisdk.sh"
PROJECT_INSTALL="$INSTALL_DIR/setup_project.sh"

# create logger
LOG_DIR="$INSTALL_DIR/logs"

if [ ! -d "$LOG_DIR" ]; then 
  mkdir -p $LOG_DIR 
fi

BUILD_LOG="$LOG_DIR/install.log"
exec > >(tee "$BUILD_LOG") 2>&1

# Step 1: install OpenNISDK
echo "[1/2] Install: installing opennisdk..."
sudo chmod +x "$OPENNISDK_INSTALL"
sudo "$OPENNISDK_INSTALL"

# Step 2: install project
echo "[2/2] installing project..."
sudo chmod +x "$PROJECT_INSTALL"
sudo "$PROJECT_INSTALL"

echo "✅ Setup complete.  Logs saved to: $BUILD_LOG"
exit 0