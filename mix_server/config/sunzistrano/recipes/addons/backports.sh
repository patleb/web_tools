case "$OS_NAME" in
ubuntu)
  sun.install "appstream/$UBUNTU_CODENAME-backports"
  appstreamcli refresh --force
;;
esac
