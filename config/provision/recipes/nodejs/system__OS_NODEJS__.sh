NODE_VERSION=<%= @sun.os_nodejs || '10' %>

case "$OS" in
ubuntu)
  curl -sL https://deb.nodesource.com/setup_$NODE_VERSION.x | sudo -E bash -
  curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
;;
centos)
  curl -sL https://rpm.nodesource.com/setup_$NODE_VERSION.x | sudo bash -
  curl -sL https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
;;
esac

sun.update
sun.install "nodejs"
sun.install "yarn"
