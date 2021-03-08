# TODO install from binaries instead, too long to build 13 minutes 14 seconds
# https://gist.github.com/tqyq/955fcf2e505894d59db6b0e771cfe3e8
# https://dist.apache.org/repos/dist/release/madlib/1.17.0/apache-madlib-1.17.0-bin-Linux.deb
sun.install "pgxnclient"
sun.install "$PG_PACKAGES"
sun.lock "$PG_PACKAGES"

pgxn install madlib
