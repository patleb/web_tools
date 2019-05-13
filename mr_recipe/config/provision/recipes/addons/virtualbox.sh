sh -c "echo 'deb http://download.virtualbox.org/virtualbox/debian $UBUNTU_CODENAME contrib' >> /etc/apt/sources.list"
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
sun.update

sun.install "virtualbox-5.2"
sun.install "dkms"
