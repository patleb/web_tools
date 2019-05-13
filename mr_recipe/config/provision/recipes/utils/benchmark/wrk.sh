cd $HOME
git clone git://github.com/wg/wrk.git
cd wrk && make
ln -sf $(realpath wrk) /usr/bin/wrk
