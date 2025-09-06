### References
# https://github.com/docker-library/ruby/blob/master/3.4/slim-bookworm/Dockerfile
# https://github.com/rails/rails/blob/main/railties/lib/rails/generators/rails/app/templates/Dockerfile.tt
# https://github.com/rails/rails/blob/main/railties/lib/rails/generators/app_base.rb
# https://github.com/rbenv/ruby-build/wiki
# https://github.com/docker-library/postgres/blob/master/17/bookworm/Dockerfile
if [[ "${env}" != 'virtual' && "${env}" != 'computer' ]]; then
  case "$OS_NAME" in
  ubuntu)
    sun.backup_compare '/etc/apt/apt.conf.d/50unattended-upgrades'
  ;;
  esac
fi

<% %W(
  bzip2
  ca-certificates
  libffi-dev
  libgmp-dev
  libssl-dev
  libyaml-dev
  procps
  zlib1g-dev

  dpkg-dev
  libgdbm-dev
  autoconf
  g++
  gcc
  libbz2-dev
  libgdbm-compat-dev
  libglib2.0-dev
  libncurses-dev
  libxml2-dev libxml2-utils
  libxslt-dev
  make
  wget
  xz-utils

  curl
  sqlite3
  postgresql-client
  libvips libpng-dev libjpeg-dev
  libjemalloc-dev

  build-essential
  git
  pkg-config
  libpq-dev
  node-gyp
  python-is-python3

  patch
  rustc
  libreadline6-dev
  libncurses5-dev
  libgdbm6
  libdb-dev
  uuid-dev

  libnss-wrapper
  zstd

  at
  lz4
  golang-go
  parallel
  pigz
  pssh
  pv
  rename
  rsync
  whois
).compact_blank.each do |package| %>
  sun.install "<%= package %>"
<% end %>

if ! cat "$HOME/.bashrc" | grep -Fq /go/bin/; then
  echo 'export PATH="$HOME/go/bin:$PATH"' >> "$HOME/.bashrc"
fi

echo "nodejs $(nodejs --version)"
python --version | tr '[:upper:]' '[:lower:]'
rustc  --version
go       version
echo "sqlite $(sqlite3 --version)"
psql   --version
