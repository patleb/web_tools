nodejs=${nodejs:-14}

if [ -f /etc/apt/sources.list.d/nodesource.list ]; then
  sun.remove 'nodejs'
  rm -f /etc/apt/sources.list.d/nodesource.list
fi
curl -sL https://deb.nodesource.com/setup_${nodejs}.x | bash -
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb [arch=$ARCH] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

sun.update
sun.install "nodejs"
sun.install "yarn"
echo 'export PATH="$(yarn global bin):$PATH"' >> ~/.bashrc
