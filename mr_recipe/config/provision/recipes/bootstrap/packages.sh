<% %w(
  apt-transport-https
  autoconf
  bison
  build-essential
  ca-certificates
  castxml
  clang
  git
  imagemagick
  libcurl4-openssl-dev
  libffi-dev
  libgdbm-dev
  libgdbm3
  libgmp-dev
  libncurses5-dev
  libreadline-dev
  libssl-dev
  libvips
  libvips-dev
  libvips-tools
  libxml2-dev
  libxslt1-dev
  libyaml-dev
  openssh-server
  openssl
  pigz
  zlib1g-dev
).each do |package| %>

  sun.install "<%= package %>"

<% end %>
