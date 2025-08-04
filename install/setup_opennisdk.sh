#!/bin/bash

set -euo pipefail

HOME="/home/pi"
PROJECT_DIR="$HOME/drone-rpi3-32-bit"
ARM_VERSION="OpenNI-Linux-Arm-2.3.0.63"
OPENNISDK_SOURCE="$PROJECT_DIR/sdks/$ARM_VERSION"
OPENNISDK_DIR="$HOME/OpenNISDK"
OPENNISDK_ARM_DIR="$OPENNISDK_DIR/$ARM_VERSION"
LIB_DIR="/lib/arm-linux-gnueabihf"
SIMPLE_READ_EX="Samples/SimpleRead"
LOG_DIR="$PROJECT_DIR/install/logs"
BUILD_LOG="$LOG_DIR/setup_opennisdk.log"

mkdir -p "$LOG_DIR"
exec > >(tee "$BUILD_LOG") 2>&1

log() { echo -e "\n[INFO] $1\n"; }

log "[1/9] Updating system packages..."
sudo apt update && sudo apt -y dist-upgrade

log "[2/9] Copying OpenNI SDK files..."
mkdir -p "$OPENNISDK_DIR"
cp -r "$OPENNISDK_SOURCE" "$OPENNISDK_DIR"

log "[3/9] Installing dependencies..."
sudo apt-get install -y build-essential freeglut3 freeglut3-dev python3-opencv

log "[4/9] Ensuring libudev is correctly installed..."
if ! ldconfig -p | grep -q libudev.so.1; then
    log "libudev.so.1 not found. Installing..."
    sudo apt install --reinstall -y libudev1
else
    log "libudev.so.1 found. Reinstalling to ensure correct version..."
    sudo apt install --reinstall -y libudev1
fi

log "[5/9] Installing OpenNI SDK..."
cd "$OPENNISDK_ARM_DIR"
chmod +x install.sh
sudo ./install.sh

log "[6/9] Sourcing OpenNI Development Environment..."
source OpenNIDevEnvironment

read -p "→ OpenNI SDK installed. Replug your device, then press ENTER." _

log "[7/9] Verifying Orbbec device detection..."
if lsusb | grep -q 2bc5:0407; then
    echo "Orbbec Astra Mini S detected."
elif lsusb | grep -q 2bc5; then
    echo "[ERROR] Non-supported Orbbec device detected (e.g., Astra Pro)."
    exit 1
else
    echo "[ERROR] No Orbbec device found."
    exit 1
fi

log "[8/9] Building sample code..."
cd "$SIMPLE_READ_EX"
make

log "[9/9] Verifying build..."
file "$OPENNISDK_DIR/$SIMPLE_READ_EX/Bin/Arm-Release/SimpleRead"

log "✅ OpenNI SDK setup complete. Logs saved to: $BUILD_LOG"
exit 0