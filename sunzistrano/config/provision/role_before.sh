#!/bin/bash
set -e
set -u
<% if @sun.debug == 'trace' %>
  set -x
<% end %>

if which apt-get >/dev/null 2>&1; then
  export UBUNTU_OS=true
  export CENTOS_OS=false
  export OS=ubuntu
  export os_package_get=apt-get
  export os_package_update='apt update'
  export os_package_upgrade='apt upgrade'
  export os_package_installed='dpkg -s'
elif which yum >/dev/null 2>&1; then
  export UBUNTU_OS=false
  export CENTOS_OS=true
  export OS=centos
  export os_package_get=yum
  export os_package_update='yum check-update'
  export os_package_upgrade='yum update'
  export os_package_installed='rpm -q'
else
  echo "Unsupported OS"
  exit 1
fi

source /etc/os-release
export TERM=linux
source sun.sh

export ROLE_ID=<%= @sun.role %>
export ROLE_START=$(sun.start_time)
export REBOOT_FORCE=false

case "$OS" in
ubuntu)
  export DEBIAN_FRONTEND=noninteractive
;;
centos)
  export HOME=/home/<%= @sun.username %>
  if ! sun.installed "rpmdevtools"; then
    sun.mute "$os_package_get -y install rpmdevtools"
  fi
;;
esac

sun.setup_progress
source roles/hook_before.sh
