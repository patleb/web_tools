case "$OS" in
ubuntu)
  sun.install "appstream/xenial-backports" # TODO bionic-backports
  appstreamcli refresh --force
;;
esac
