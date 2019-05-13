CTOP_VERSION=<%= @sun.docker_ctop || '0.7.2' %>

wget "https://github.com/bcicen/ctop/releases/download/v$CTOP_VERSION/ctop-$CTOP_VERSION-linux-amd64" -O /usr/local/bin/ctop

chmod +x /usr/local/bin/ctop
