__ROCKSDB__=${__ROCKSDB__:-6.20.3}
CORES=$(nproc)

sun.install "libgflags-dev"
sun.install "libsnappy-dev"
sun.install "zlib1g-dev"
sun.install "libbz2-dev"
sun.install "libzstd-dev"

wget "https://github.com/facebook/rocksdb/archive/v$__ROCKSDB__.zip"
unzip "v$__ROCKSDB__.zip"
cd "rocksdb-$__ROCKSDB__"
make -j$CORES static_lib && sudo make install-static
make clean && sudo make -j$CORES shared_lib && sudo make install-shared
ldconfig
