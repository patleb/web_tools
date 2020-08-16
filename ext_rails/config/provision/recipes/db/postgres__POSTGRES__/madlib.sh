# TODO install from binaries instead, too long to build 13 minutes 14 seconds
# https://gist.github.com/tqyq/955fcf2e505894d59db6b0e771cfe3e8
sun.install "pgxnclient"
sun.install "$PG_PACKAGES"
sun.lock "$PG_PACKAGES"

pgxn install madlib
