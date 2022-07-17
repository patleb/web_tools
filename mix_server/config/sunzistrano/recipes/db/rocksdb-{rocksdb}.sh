rocksdb=${rocksdb:-6.20.3}
CORES=$(nproc)

sun.install "libgflags-dev"
sun.install "libsnappy-dev"
sun.install "zlib1g-dev"
sun.install "libbz2-dev"
sun.install "libzstd-dev"

wget "https://github.com/facebook/rocksdb/archive/v${rocksdb}.zip"
unzip "v${rocksdb}.zip"
cd "rocksdb-${rocksdb}"
make -j$CORES static_lib && sudo make install-static
make clean && sudo make -j$CORES shared_lib && sudo make install-shared
ldconfig
