__NODEJS__=${__NODEJS__:-14}

curl -sL https://deb.nodesource.com/setup_$__NODEJS__.x | bash -
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb [arch=$ARCH] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

sun.update
sun.install "nodejs"
sun.install "yarn"
