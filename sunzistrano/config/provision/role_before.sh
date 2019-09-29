#!/bin/bash
set -e
set -u

if which apt-get >/dev/null 2>&1; then
  export OS=ubuntu
  export os_package_get='apt-get'
  export os_package_update='apt update'
  export os_package_upgrade='apt upgrade'
  export os_package_installed='dpkg -s'
  export os_package_lock='apt-mark hold'
  export os_package_unlock='apt-mark unhold'
elif which yum >/dev/null 2>&1; then
  export OS=centos
  export os_package_get='yum'
  export os_package_update='yum clean expire-cache'
  export os_package_upgrade='yum --exclude=kernel* update'
  export os_package_installed='rpm -q'
  export os_package_lock='yum versionlock add'
  export os_package_unlock='yum versionlock delete'
else
  echo "Unsupported OS"
  exit 1
fi

source /etc/os-release
export TERM=linux

export ROLE_START=$(sun.start_time)
export REBOOT_FORCE=false

<% @sun.attributes.each do |attribute, value| %>
  export __<%= attribute.upcase %>__=<%= value.respond_to?(:call) ? value.call : value %>
<% end %>

source sun.sh

case "$OS" in
ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  # TODO https://help.ubuntu.com/community/RPM/AlienHowto
;;
centos)
  export HOME=/home/$__USERNAME__
  if ! sun.installed "rpmdevtools"; then
    sun.mute "$os_package_get -y install rpmdevtools"
  fi
;;
esac

sun.setup_progress
if [[ "$__DEBUG__" == 'trace' ]]; then
  set -x
fi
source roles/hook_before.sh
