# TODO install from binaries instead, too long to build 13 minutes 14 seconds
# https://gist.github.com/tqyq/955fcf2e505894d59db6b0e771cfe3e8

PG_MAJOR="<%= @sun.postgres %>"
PG_VERSION=$(sun.current_version 'postgresql')
PG_PACKAGES="postgresql-server-dev-$PG_MAJOR postgresql-plpython-$PG_MAJOR"

sun.install "m4"
sun.install "patch"
sun.install "cmake"
sun.install "pgxnclient"
sun.install "$PG_PACKAGES"
sun.lock "$PG_PACKAGES"

pgxn install madlib
