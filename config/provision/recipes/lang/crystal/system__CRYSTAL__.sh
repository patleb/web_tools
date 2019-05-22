case "$OS" in
ubuntu)
  curl https://dist.crystal-lang.org/apt/setup.sh | sudo bash
;;
centos)
  curl https://dist.crystal-lang.org/rpm/setup.sh | sudo bash
;;
esac

sun.install "crystal"
