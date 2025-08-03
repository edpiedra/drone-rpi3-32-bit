DRONE ENVIRONMENT

Install Emlid image
-------------------------------------------------------------------
> emlid-raspian-20220608.img.xz using Raspberry Pi Imager

> boot and follow ArduPilot setup instructions

> use sudo raspi-config to change hostname and password and reboot


Install OpenNISDK, virtual environment, and packages
-------------------------------------------------------------------
> clone repository and install project
```
sudo apt update 
sudo apt install -y git
cd ~
sudo git clone https://github.com/edpiedra/drone-rpi3-32-bit.git

sudo chmod +x ./drone-rpi3-32-bit/install/install.sh
sudo ./drone-rpi3-32-bit/install/install.sh
```

> run test sample
```
cd ~/drone-rpi3-32-bit
source .venv/bin/activate
python -m test-body-detection
```

> ===== to update local repository =====
```
cd ~/drone-rpi3-32-bit
sudo git reset --hard
sudo git pull origin
```