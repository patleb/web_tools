sun.mute "dpkg --configure -a"
sun.install "linux-headers-$(uname -r)"
sun.update
yes | sun.upgrade
