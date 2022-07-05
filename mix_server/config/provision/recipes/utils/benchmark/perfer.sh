cd $HOME
git clone https://github.com/ohler55/perfer.git
cd perfer && make
ln -sf $(realpath bin/perfer) /usr/bin/perfer
