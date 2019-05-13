cd $HOME
git clone git://github.com/ohler55/perfer.git
cd perfer && make
ln -sf $(realpath bin/perfer) /usr/bin/perfer
