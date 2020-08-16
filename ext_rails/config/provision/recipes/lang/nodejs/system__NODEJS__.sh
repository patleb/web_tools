__NODEJS__=${__NODEJS__:-10}

case "$OS" in
ubuntu)
  curl -sL https://deb.nodesource.com/setup_$__NODEJS__.x | bash -
  curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
;;
centos)
  curl -sL https://rpm.nodesource.com/setup_$__NODEJS__.x | bash -
  curl -sL https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
;;
esac

sun.update
sun.install "nodejs"
sun.install "yarn"
