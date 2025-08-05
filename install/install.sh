#!/bin/bash

set -euo pipefail

SCRIPT_NAME=$(basename "$0")

HOME="/home/pi"
PROJECT_DIR="$HOME/drone-rpi3-32-bit"

ARM_VERSION="OpenNI-Linux-Arm-2.3.0.63"
OPENNISDK_SOURCE="$PROJECT_DIR/sdks/$ARM_VERSION"
OPENNISDK_DIR="$HOME/openni"
OPENNISDK_DEST="$OPENNISDK_DIR/$ARM_VERSION"
GNU_LIB_DIR="/lib/arm-linux-gnueabihf"
SIMPLE_READ_EXAMPLE="$OPENNISDK_DEST/Samples/SimpleRead"
OPENNI2_REDIST_DIR="$OPENNISDK_DEST/Redist"

DRONE_DIR="$HOME/drone-rpi3-32-bit"
NAVIO2_GIT="https://github.com/emlid/Navio2.git"
NAVIO2_DIR="$HOME/Navio2"
NAVIO2_PYTHON_DIR="$NAVIO2_DIR/Python"
NAVIO2_WHEEL="$NAVIO2_PYTHON_DIR/dist/navio2-1.0.0-py3-none-any.whl"

#OPENCV_VERSION="4.5.5"
#PYTHON_VERSION="3.7"
#VENV_NAME="cv_env"
#VENV_PATH="$HOME/${VENV_NAME}"
#WHEEL_DIR="$HOME/opencv_wheels"
#OPENCV_BUILD="$HOME/opencv_build"

PROJECT_INSTALL_DIR="$PROJECT_DIR/install"

LOG_DIR="$HOME/install_logs"
BUILD_LOG="$LOG_DIR/install.log"

mkdir -p "$LOG_DIR"
exec > >(tee "$BUILD_LOG") 2>&1

log() { 
    local message="$1"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local calling_function=${FUNCNAME[1]:-"main"}
    local line_number=${BASH_LINENO[0]:-0}

    local formatted_message="[${timestamp}] [${SCRIPT_NAME}:${calling_function}:${line_number}] ${message}"
    echo -e "\n${formatted_message}\n"
 }

log "[ 1/11] updating system packages..."
sudo apt-get update && sudo apt-get -y -q dist-upgrade

log "[ 2/11] installing system packages..."
sudo apt-get install -y -q build-essential freeglut3 freeglut3-dev python3-opencv \
    python3-numpy cmake git pkg-config libgtk-3-dev \
    libavcodec-dev libavformat-dev libswscale-dev libv4l-dev \
    libxvidcore-dev libx264-dev libjpeg-dev libpng-dev libtiff-dev \
    gfortran openexr libatlas-base-dev libtbb2 libtbb-dev libdc1394-22-dev \
    libopenexr-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    python3.7-dev python3.7-venv python3-pip 

sudo apt-get install --reinstall -y -q libudev1

log "[ 3/11] copying OpenNI SDK distribution..."
if [ -d "$OPENNISDK_DIR" ]; then 
    rm -r "$OPENNISDK_DIR"
fi 

mkdir "$OPENNISDK_DIR"
sudo cp "$OPENNISDK_SOURCE" "$OPENNISDK_DIR"

log "[ 4/11] installing OpenNI SDK..."
cd "$OPENNISDK_DEST"
chmod +x install.sh
sudo ./install.sh

log "[ 5/11] sourcing OpenNI development environment..."
source OpenNIDevEnvironment

read -p "→ OpenNI SDK installed. Replug your device, then press ENTER." _

log "[ 6/11] verifying Orbbec device..."
if lsusb | grep -q 2bc5:0407; then
    echo "Orbbec Astra Mini S detected."
elif lsusb | grep -q 2bc5; then
    echo "[ERROR] Non-supported Orbbec device detected (e.g., Astra Pro)."
    exit 1
else
    echo "[ERROR] No Orbbec device found."
    exit 1
fi

log "[ 7/11] building $SIMPLE_READ_EXAMPLE..."
cd "$SIMPLE_READ_EXAMPLE"
make 

if [ ! -f "$NAVIO2_WHEEL" ]; then 
    log "[ 8/11] cloning from $NAVIO2_GIT..."

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
else 
    log "[ 8/11] skipping cloning $NAVIO2_GIT because $NAVIO2_WHEEL aleady exists..."
fi

log "[ 9/11] checking for drone project virtual environment..."
cd "$DRONE_DIR"

if [ ! -d .venv ]; then 
    sudo python3 -m venv .venv --system-site-packages
    source .venv/bin/activate
    sudo python3 -m pip install "$NAVIO2_PYTHON_DIR/dist/navio2-1.0.0-py3-none-any.whl"
    sudo python3 -m pip install -r requirements.txt
fi

log "[10/11] adding environmental variables..."
if ! grep -q "export OPENNI2_REDIST=.*$OPENNI2_REDIST_DIR" ~/.bashrc; then 
    echo "OPENNI2_REDIST=$OPENNI2_REDIST_DIR" >> ~/.bashrc
    echo "-> added $OPENNI2_REDIST_DIR to OPENNI2_REDIST environmental variable in ~/.bashrc"
    source ~/.bashrc 
fi 

log "[11/11] verifying builds..."
file "$SIMPLE_READ_EXAMPLE/Bin/Arm-Release/SimpleRead"
file "$NAVIO2_WHEEL"

log "✅ Install complete. Logs saved to: $BUILD_LOG"
exit 0