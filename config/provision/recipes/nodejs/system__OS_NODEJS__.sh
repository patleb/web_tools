NODE_VERSION=<%= @sun.apt_nodejs || '10' %>

curl -sL https://deb.nodesource.com/setup_$NODE_VERSION.x | sudo -E bash -

sun.install "nodejs"
