# Coral setup
sudo apt install ./drivers_tpu/libedgetpu1-std_16.0tf2.17.0-1.bookworm_arm64.deb -y
# sudo echo "dtparam=pciex1" >> /boot/firmware/config.txt
# sudo echo "kernel=kernel8.img" >> /boot/firmware/config.txt
# sudo echo "dtoverlay=pineboards-hat-ai" >> /boot/firmware/config.txt
echo '[all]' | sudo tee -a /boot/firmware/config.txt
echo 'dtparam=pciex1_gen=3' | sudo tee -a /boot/firmware/config.txt
echo '# Enable the PCIe External connector.' | sudo tee -a /boot/firmware/config.txt
echo 'dtparam=pciex1' | sudo tee -a /boot/firmware/config.txt
echo 'kernel=kernel8.img' | sudo tee -a /boot/firmware/config.txt
echo '# Enable Pineboards Hat Ai' | sudo tee -a /boot/firmware/config.txt
echo 'dtoverlay=pineboards-hat-ai' | sudo tee -a /boot/firmware/config.txt
sudo echo "deb https://packages.cloud.google.com/apt coral-edgetpu-stable main" | tee /etc/apt/sources.list.d/coral-edgetpu.list
sudo curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
sudo apt update && sudo apt upgrade -y
sudo apt install cmake build-essential libgdal-dev devscripts debhelper dkms dh-dkms git -y

# Gasket driver
cd ~ && git clone https://github.com/google/gasket-driver.git && cd gasket-driver && debuild -us -uc -tc -b && cd .. &&  sudo dpkg -i gasket-dkms_1.0-18_all.deb
sudo sh -c "echo 'SUBSYSTEM==\"apex\", MODE=\"0660\", GROUP=\"apex\"' >> /etc/udev/rules.d/65-apex.rules"
sudo groupadd apex
sudo adduser $USER apex
sudo usermod -aG plugdev $USER
sudo depmod -a

# # Docker
# curl -fsSL https://get.docker.com -o get-docker.sh
# sudo apt install uidmap -y
# sudo sh get-docker.sh && dockerd-rootless-setuptool.sh install

python -m venv ~/venv && source ~/venv/bin/activate && pip install tensorflow tflite_runtime

# Reboot
sudo reboot

#  curl https://gist.githubusercontent.com/dataslayermedia/714ec5a9601249d9ee754919dea49c7e/raw/32d21f73bd1ebb33854c2b059e94abe7767c3d7e/coral-ai-pcie-edge-tpu-raspberrypi-5-setup | sh