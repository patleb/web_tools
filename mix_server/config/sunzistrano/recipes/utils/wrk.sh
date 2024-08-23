cd $HOME
git clone https://github.com/wg/wrk.git
cd wrk && make
ln -sf $(realpath wrk) /usr/bin/wrk
