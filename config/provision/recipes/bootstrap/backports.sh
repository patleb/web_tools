case "$OS" in
ubuntu)
  sun.install "appstream/xenial-backports"
  appstreamcli refresh --force
;;
esac
