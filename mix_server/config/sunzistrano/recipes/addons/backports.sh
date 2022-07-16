case "$OS" in
ubuntu)
  sun.install "appstream/$UBUNTU_CODENAME-backports"
  appstreamcli refresh --force
;;
esac
