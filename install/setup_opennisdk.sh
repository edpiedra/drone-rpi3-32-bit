#!/bin/bash

set -e

# configureation
HOME="/home/pi"
PROJECT_DIR="$HOME/drone-rpi3-32-bit"
ARM_VERSION="OpenNI-Linux-Arm-2.3.0.63"
OPENNISDK_SOURCE="$PROJECT_DIR/sdks/$ARM_VERSION"
OPENNISDK_DIR="$HOME/OpenNISDK"
OPENNISDK_ARM_DIR="$OPENNISDK_DIR/$ARM_VERSION"
LIB_DIR="/lib/arm-linux-gnueabihf"
SIMPLE_READ_EX="Samples/SimpleRead"
INSTALL_DIR="$PROJECT_DIR/install"
LOG_DIR="$INSTALL_DIR/logs"

if [ ! -d "$LOG_DIR" ]; then 
  mkdir -p $LOG_DIR 
fi

BUILD_LOG="$LOG_DIR/setup_opennisdk.log"
exec > >(tee "$BUILD_LOG") 2>&1

# Step 1: Update system packages
echo "[1/9] OpenNISDK: updating system packages..."
sudo apt update && sudo apt -y dist-upgrade

# Step 2: copying opennisdk
echo "[2/9] OpenNISDK: copying OpenNISDK files..."

if [ ! -d "$OPENNISDK_DIR" ]; then 
  cd "$HOME"
  mkdir "$OPENNISDK_DIR"
fi 

scp -r "$OPENNISDK_SOURCE" "$OPENNISDK_DIR"

# Step 3: Installing system packages
echo "[3/9] OpenNISDK: installing system packages..."
sudo apt-get install -y build-essential freeglut3 freeglut3-dev python3-opencv

# Step 4: check for libudev.so.1
echo "[4/9] OpenNISDK: checking libudev..."

if ldconfig -p | grep -q libudev.so.1; then
    echo "libudev.so.1 already exists."
else
    echo "libudev.so.1 not found. Attempting to create symlink..."

    cd "$LIB_DIR" || { echo "Failed to cd to $LIB_DIR"; exit 1; }
    LIBUDEV_REAL=$(ls libudev.so.*.*.* 2>/dev/null | head -n 1)

    if [ -z "$LIBUDEV_REAL" ]; then
        echo "No suitable libudev.so.x.x.x found in $LIB_DIR"
        exit 1
    fi

    echo "Creating symlink: libudev.so.1 -> $LIBUDEV_REAL"
    sudo ln -sf "$LIBUDEV_REAL" libudev.so.1

    if [ $? -eq 0 ]; then
        echo "Symlink created successfully."
    else
        echo "Failed to create symlink."
        exit 1
    fi
fi 

# Step 5: installing opennisdk
echo "[5/9] OpenNISDK: installing OpenNISDK version $ARM_VERSION..."
cd "$OPENNISDK_ARM_DIR"
sudo chmod +x install.sh
sudo ./install.sh 

# Step 6: check for device
read -p "→ OpenNISDK installed. Replug your device before you hit ENTER." RESP

echo "[6/9] OpenNISDK: checking for device..."

if lsusb -p | grep 2bc5:0407; then 
    echo "-> Orbbec device successfully detected..."
else
    if lsusb -p | grep 2bc5; then 
        echo " The Orbbec device needs to be an Astra Mini S (no Pro)..."
    else
        echo "unable to detect Orbbec device"
    fi 
    exit 1
fi 

# Step 7: starting OpenNIDevEnvironment
echo "[7/9] OpenNISDK: starting OpenNI development environment..."
source OpenNIDevEnvironment

# Step 8: build a sample
echo "[8/9] OpenNISDK: building samples..."
cd "$SIMPLE_READ_EX"
make 

# Step 9: verify example got built
echo "[9/9] OpenNISDK: verifying samples..."
file "$OPENNISDK_DIR/$SIMPLE_READ_EX/Bin/Arm-Release/SimpleRead"

echo "✅ Setup complete.  Logs saved to: $BUILD_LOG"
exit 0