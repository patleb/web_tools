sun.remove "parallel"

wget https://git.savannah.gnu.org/cgit/parallel.git/plain/src/parallel
chmod 755 parallel
cp parallel sem
cp parallel /bin
cp sem /bin
mv parallel sem /usr/bin/
