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
source sun.sh
case "$OS" in
ubuntu)
  export DEBIAN_FRONTEND=noninteractive
;;
centos)
  sun.installed "rpmdevtools"
  if [[ $? -ne 0 ]]; then
    sun.mute "$os_package_get -y install rpmdevtools"
  fi
;;
esac
export TERM=linux

sun.setup_progress
ROLE_ID=<%= @sun.role %>
ROLE_START=$(sun.start_time)
REBOOT_FORCE=false

source roles/hook_before.sh
