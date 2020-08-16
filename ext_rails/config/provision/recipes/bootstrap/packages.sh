<% %W(
  #{sun.os.ubuntu? ? 'apt-transport-https'               : ''}
  autoconf
  bc
  bison
  #{sun.os.ubuntu? ? 'build-essential'                   : 'gcc gcc-c++ bzip2 make automake libtool rpm-build redhat-rpm-config'}
  ca-certificates
  #{sun.os.ubuntu? ? ('castxml' if sun.ruby_cpp)         : ''}
  #{'clang' if sun.ruby_cpp}
  cmake
  git
  #{sun.os.ubuntu? ? 'dirmngr gnupg'                     : 'pygpgme'}
  #{sun.os.ubuntu? ? 'imagemagick'                       : 'ImageMagick ImageMagick-devel'}
  #{sun.os.ubuntu? ? 'libcurl4-openssl-dev'              : 'libcurl-devel'}
  #{sun.os.ubuntu? ? 'libffi-dev'                        : 'libffi-devel'}
  #{sun.os.ubuntu? ? 'libgdbm5 libgdbm-dev'              : 'gdbm-devel'}
  #{sun.os.ubuntu? ? 'libgmp-dev'                        : 'gmp-devel'}
  #{sun.os.ubuntu? ? 'libncurses5-dev'                   : 'ncurses-devel'}
  #{sun.os.ubuntu? ? 'libreadline-dev'                   : 'readline readline-devel'}
  #{sun.os.ubuntu? ? 'libssl-dev'                        : 'openssl-devel'}
  #{sun.os.ubuntu? ? 'libvips libvips-dev libvips-tools' : 'vips vips-devel vips-tools'}
  #{sun.os.ubuntu? ? 'libxml2-dev libxml2-utils'         : 'libxml2 libxml2-devel'}
  #{sun.os.ubuntu? ? 'libxslt1-dev'                      : 'libxslt-devel'}
  #{sun.os.ubuntu? ? 'libyaml-dev'                       : 'libyaml-devel'}
  m4
  mmv
  openssh-server
  openssl
  patch
  pigz
  pssh
  pv
  #{sun.os.ubuntu? ? 'sqlite3 libsqlite3-dev'            : 'sqlite sqlite-devel'}
  #{sun.os.ubuntu? ? 'software-properties-common'        : ''}
  time
  #{sun.os.ubuntu? ? ''                                  : 'yum-utils'}
  #{sun.os.ubuntu? ? ''                                  : 'yum-versionlock'}
  #{sun.os.ubuntu? ? 'zlib1g-dev'                        : 'zlib zlib-devel'}
).reject(&:blank?).each do |package| %>

  sun.install "<%= package %>"

<% end %>
