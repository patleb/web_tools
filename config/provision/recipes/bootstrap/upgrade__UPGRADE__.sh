case "$OS" in
ubuntu)
  sun.mute "dpkg --configure -a"
;;
esac
sun.update
yes | sun.upgrade

sun.install "curl"
sun.install "rsync"
