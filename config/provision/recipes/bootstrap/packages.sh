<% if @sun.os.centos? %>
  yes | yum localinstall --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm
  yes | yum localinstall --nogpgcheck http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-latest-7.noarch.rpm
  yes | yum localinstall --nogpgcheck http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
<% end %>
<% %W(
  #{'apt-transport-https' if @sun.os.ubuntu?}
  autoconf
  bison
  #{@sun.os.ubuntu? ? 'build-essential'      : 'gcc gcc-c++ make rpm-build redhat-rpm-config'}
  ca-certificates
  #{'castxml' if @sun.os.ubuntu?}
  clang
  git
  #{@sun.os.ubuntu? ? 'imagemagick'          : 'ImageMagick ImageMagick-devel'}
  #{@sun.os.ubuntu? ? 'libcurl4-openssl-dev' : 'openssl-devel'}
  #{@sun.os.ubuntu? ? 'libffi-dev'           : 'libffi-devel'}
  #{@sun.os.ubuntu? ? 'libgdbm-dev'          : 'libgdbm-devel'}
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
).reject(&:blank?).each do |package| %>

  sun.install "<%= package %>"

<% end %>
