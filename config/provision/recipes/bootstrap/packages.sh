<% %W(
  #{@sun.os.ubuntu? ? 'apt-transport-https'  : ''}
  autoconf
  bison
  #{@sun.os.ubuntu? ? 'build-essential'      : 'gcc gcc-c++ make rpm-build redhat-rpm-config'}
  #{@sun.os.ubuntu? ? ''                     : 'bzip2'}
  ca-certificates
  #{@sun.os.ubuntu? ? 'castxml'              : ''}
  clang
  git
  #{@sun.os.ubuntu? ? 'dirmngr gnupg'        : 'pygpgme'}
  #{@sun.os.ubuntu? ? 'imagemagick'          : 'ImageMagick ImageMagick-devel'}
  #{@sun.os.ubuntu? ? 'libcurl4-openssl-dev' : 'libcurl-devel'}
  #{@sun.os.ubuntu? ? 'libffi-dev'           : 'libffi-devel'}
  #{@sun.os.ubuntu? ? 'libgdbm-dev libgdbm5' : 'gdbm-devel'}
  #{@sun.os.ubuntu? ? 'libgmp-dev'           : 'gmp-devel'}
  #{@sun.os.ubuntu? ? 'libncurses5-dev'      : 'ncurses-devel'}
  #{@sun.os.ubuntu? ? 'libreadline-dev'      : 'readline-devel'}
  #{@sun.os.ubuntu? ? 'libsqlite3-dev'       : 'sqlite-devel'}
  #{@sun.os.ubuntu? ? 'libssl-dev'           : 'openssl-devel'}
  #{@sun.os.ubuntu? ? 'libvips'              : 'vips'}
  #{@sun.os.ubuntu? ? 'libvips-dev'          : 'vips-devel'}
  #{@sun.os.ubuntu? ? 'libvips-tools'        : 'vips-tools'}
  #{@sun.os.ubuntu? ? 'libxml2-dev'          : 'libxml2-devel'}
  #{@sun.os.ubuntu? ? 'libxml2-utils'        : 'libxml2'}
  #{@sun.os.ubuntu? ? 'libxslt1-dev'         : 'libxslt-devel'}
  #{@sun.os.ubuntu? ? 'libyaml-dev'          : 'libyaml-devel'}
  openssh-server
  openssl
  pigz
  #{@sun.os.ubuntu? ? 'sqlite3'              : 'sqlite'}
  #{@sun.os.ubuntu? ? ''                     : 'yum-utils'}
  #{@sun.os.ubuntu? ? ''                     : 'yum-versionlock'}
).reject(&:blank?).each do |package| %>

  sun.install "<%= package %>"

<% end %>
