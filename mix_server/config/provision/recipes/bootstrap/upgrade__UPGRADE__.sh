case "$OS" in
ubuntu)
  sun.mute "dpkg --configure -a"
  sun.install "linux-headers-$(uname -r)"
;;
centos)
  yes | yum localinstall --nogpgcheck https://centos7.iuscommunity.org/ius-release.rpm
  yes | yum localinstall --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm
  yes | yum localinstall --nogpgcheck http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
  yes | yum localinstall --nogpgcheck http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
  if [[ ! $(grep -Fx "enabled=1" "/etc/yum.repos.d/remi.repo") ]]; then
    sed -i '0,/enabled=0/s//enabled=1/' /etc/yum.repos.d/remi.repo
  fi
;;
esac
sun.update
yes | sun.upgrade

sun.install "curl"
sun.install "wget"
sun.install "rsync"
