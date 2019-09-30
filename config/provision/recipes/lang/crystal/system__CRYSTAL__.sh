case "$OS" in
ubuntu)
  curl https://dist.crystal-lang.org/apt/setup.sh | bash
;;
centos)
  curl https://dist.crystal-lang.org/rpm/setup.sh | bash
;;
esac

sun.install "crystal"
