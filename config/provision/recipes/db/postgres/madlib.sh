# TODO install from binaries instead, too long to build 13 minutes 14 seconds
# https://gist.github.com/tqyq/955fcf2e505894d59db6b0e771cfe3e8

PG_VERSION=$(sun.current_version 'postgresql')
PG_MAJOR=$(sun.pg_major_version "$PG_VERSION")
PG_HOLD="postgresql-server-dev-$PG_MAJOR postgresql-plpython-$PG_MAJOR"

sun.install "m4"
sun.install "patch"
sun.install "cmake"
sun.install "pgxnclient"
sun.install "postgresql-server-dev-$PG_MAJOR"
sun.install "postgresql-plpython-$PG_MAJOR"
apt-mark hold $PG_HOLD

pgxn install madlib
