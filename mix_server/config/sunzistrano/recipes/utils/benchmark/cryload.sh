cd $HOME
git clone https://github.com/bararchy/cryload.git
cd cryload && crystal build src/cryload.cr --release
ln -sf $(realpath cryload) /usr/bin/cryload
