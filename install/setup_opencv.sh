#!/bin/bash

set -euo pipefail

SCRIPT_NAME=$(basename "$0")

HOME="/home/pi"
OPENCV_VERSION="4.5.5"
PYTHON_VERSION="3.7"
VENV_NAME="cv_env"
VENV_PATH="$HOME/${VENV_NAME}"
WHEEL_DIR="$HOME/opencv_wheels"
OPENCV_BUILD="$HOME/opencv_build"
LOG_DIR="$OPENCV_BUILD/logs"
BUILD_LOG="$LOG_DIR/install.log"

mkdir -p "$LOG_DIR"
exec > >(tee "$BUILD_LOG") 2>&1

log() { 
    local message="$1"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local calling_function=${FUNCNAME[1]:-"main"}
#    local line_number=${BASH_LINE0[0]}

    local formatted_message="[${timestamp}] [${SCRIPT_NAME}:${calling_function}:] ${message}"
    echo -e "\n${formatted_message}\n"
 }

log "[ 1/ ] checking python version..."
PYTHON_EXEC=$(which "python$PYTHON_VERSION" || true)
if [[ -z "$PYTHON_EXEC" ]]; then
    echo "[ERROR] Python $PYTHON_VERSION not found. Please install it first."
    exit 1
fi

log "[ 2/ ] updating system packages..."
sudo apt-get update && sudo apt-get -y dist-upgrade

log "[ 3/ ] installing system packages..."
sudo apt-get install -y build-essential cmake git pkg-config libgtk-3-dev \
    libavcodec-dev libavformat-dev libswscale-dev libv4l-dev \
    libxvidcore-dev libx264-dev libjpeg-dev libpng-dev libtiff-dev \
    gfortran openexr libatlas-base-dev libtbb2 libtbb-dev libdc1394-22-dev \
    libopenexr-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    python3.7-dev python3.7-venv python3-pip python3-numpy

log "[ 4/ ] creating virtual environment..."
$PYTHON_EXEC -m venv "$VENV_PATH"
source "$VENV_PATH/bin/activate"

#log "[ 5/ ] installing python packages..."
#pip install --upgrade pip
#pip install numpy

log "[ 6/ ] downloading opencv source..."
cd "$OPENCV_BUILD"
git clone -b ${OPENCV_VERSION} https://github.com/opencv/opencv.git
git clone -b ${OPENCV_VERSION} https://github.com/opencv/opencv_contrib.git

log "[ 7/ ] configuring opencv build with cmake..."
cd "$OPENCV_BUILD/opencv"
mkdir -p build && cd build

cmake -D CMAKE_BUILD_TYPE=RELEASE \
      -D CMAKE_INSTALL_PREFIX=${VENV_PATH}/opencv-${OPENCV_VERSION} \
      -D OPENCV_EXTRA_MODULES_PATH=~/opencv_build/opencv_contrib/modules \
      -D PYTHON_EXECUTABLE=${VENV_PATH}/bin/python \
      -D BUILD_opencv_python3=ON \
      -D INSTALL_PYTHON_EXAMPLES=OFF \
      -D BUILD_EXAMPLES=OFF \
      -D BUILD_TESTS=OFF \
      -D BUILD_PERF_TESTS=OFF \
      -D ENABLE_NEON=ON \
      -D WITH_TBB=ON \
      -D WITH_V4L=ON \
      -D WITH_QT=OFF \
      -D WITH_OPENGL=ON \
      -D OPENCV_GENERATE_PKGCONFIG=ON ..

log "[ 8/ ] compiling opencv... this may take a couple of hours"
make -j$(nproc)

log "[ 9/ ] installing opencv into venv..."
make install
ldconfig

log "[10/ ] linking cv2 into site-packages..."
PYTHON_SITE_PACKAGES=$(python -c "import site; print(site.getsitepackages()[0])")
cv2_so=$(find ${VENV_PATH}/opencv-${OPENCV_VERSION}/lib/python* -name "cv2*.so" | head -n 1)
ln -sf "$cv2_so" "$PYTHON_SITE_PACKAGES/cv2.so"

log "[11/ ] building wheel file..."
cd "$OPENCV_BUILD/opencv/build"
mkdir -p "$WHEEL_DIR"
pip wheel . --wheel-dir "$WHEEL_DIR"

echo "[✅ DONE] OpenCV ${OPENCV_VERSION} installed for Python ${PYTHON_VERSION}"
echo "[📦 WHEEL] Created wheel at: $WHEEL_DIR"
