case "$OS" in
ubuntu)
  curl -sL "https://keybase.io/crystal/pgp_keys.asc" | apt-key add -
  echo "deb https://dist.crystal-lang.org/apt crystal main" | tee /etc/apt/sources.list.d/crystal.list
  sudo apt-get update
;;
centos)
  curl https://dist.crystal-lang.org/rpm/setup.sh | bash
;;
esac

sun.install "crystal"
