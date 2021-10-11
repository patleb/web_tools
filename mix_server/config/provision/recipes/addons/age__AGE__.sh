VERSION=$(curl -s "https://api.github.com/repos/FiloSottile/age/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
__AGE__=${__AGE__:VERSION}

curl -Lo age.tar.gz "https://github.com/FiloSottile/age/releases/latest/download/age-v${__AGE__}-linux-amd64.tar.gz"
tar xf age.tar.gz

mv age/age /usr/local/bin
mv age/age-keygen /usr/local/bin
