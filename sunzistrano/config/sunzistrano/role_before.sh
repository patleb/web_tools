#!/bin/bash
set -e
set -u

sun.os_name() {
  hostnamectl | grep Operating | cut -d ':' -f2 | cut -d ' ' -f2 | tr '[:upper:]' '[:lower:]'
}

sun.os_version() {
  hostnamectl | grep Operating | grep -o -E '[0-9]+' | head -n2 | paste -sd '.'
}

export OS=$(sun.os_name)
export OS_VERSION=$(sun.os_version)
case "$OS" in
ubuntu)
  export os_package_get='apt-get'
  export os_package_update='apt-get update'
  export os_package_upgrade='apt-get upgrade'
  export os_package_installed='dpkg -s'
  export os_package_lock='apt-mark hold'
  export os_package_unlock='apt-mark unhold'
;;
*)
  echo "Unsupported OS"
  exit 1
;;
esac

source /etc/os-release
export TERM=linux
<% sun.attributes.each do |attribute, value| -%>
  export <%= attribute %>=<%= value.respond_to?(:call) ? value.call : value %>
<% end -%>
export rollback=${rollback:-false}
export provision=${provision:-false}
export specialize=${specialize:-false}
export debug=${debug:-false}
export reboot=${reboot:-false}

if [[ "$OS" != "${os_name}" ]]; then
  echo "'$OS' != '${os_name}'"
  exit 1
fi

if [[ "$OS_VERSION" != "${os_version}" ]]; then
  echo "'$OS_VERSION' != '${os_version}'"
  exit 1
fi

<% sun.helpers(Sunzistrano.root).each do |file| -%>
  source helpers/<%= file %>
<% end -%>

export ROLE_START=$(sun.start_time)
export REBOOT_RECIPE=false
export REBOOT_FORCE=false
export HOME=/home/${owner_name}

export DEBIAN_FRONTEND=noninteractive
export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
export ARCH=$(dpkg --print-architecture)

trap sun.on_exit EXIT
sun.initialize

if [[ "${debug}" == 'trace' ]]; then
  set -x
fi

sun.include "roles/${role}_before.sh"
