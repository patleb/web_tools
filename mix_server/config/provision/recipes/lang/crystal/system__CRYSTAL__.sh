curl -sL "https://keybase.io/crystal/pgp_keys.asc" | apt-key add -
echo "deb [arch=$ARCH] https://dist.crystal-lang.org/apt crystal main" | tee /etc/apt/sources.list.d/crystal.list
sudo apt-get update

sun.install "crystal"
