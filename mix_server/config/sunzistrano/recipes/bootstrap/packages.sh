if [[ "${env}" != 'vagrant' ]]; then
  case "$OS_NAME" in
  ubuntu)
    sun.backup_compare '/etc/apt/apt.conf.d/50unattended-upgrades'
  ;;
  esac
fi

<% %W(
  apt-transport-https
  at
  autoconf
  bc
  bison
  build-essential
  ca-certificates
  #{'castxml' if sun.ruby_cpp}
  #{'clang' if sun.ruby_cpp}
  cmake
  git
  dirmngr gnupg
  imagemagick libpng-dev libjpeg-dev
  libcurl4-openssl-dev
  libevent-dev
  libffi-dev
  libgdbm6 libgdbm-dev
  libgmp-dev
  liblz4-dev
  libncurses5-dev
  libpcre2-dev
  libreadline-dev
  libssl-dev
  libxml2-dev libxml2-utils
  libxslt1-dev
  libyaml-dev
  m4
  mmv
  net-tools
  openssh-server
  openssl
  patch
  pigz
  pssh
  pv
  sqlite3 libsqlite3-dev
  software-properties-common
  time
  whois
  zlib1g-dev
).reject(&:blank?).each do |package| %>

  sun.install "<%= package %>"

<% end %>
