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
  export __<%= attribute.upcase %>__=<%= value.respond_to?(:call) ? value.call : value %>
<% end -%>
export __APP__=$__APPLICATION__
export __ENV__=$__STAGE__
export __ROLLBACK__=${__ROLLBACK__:-false}
export __SPECIALIZE__=${__SPECIALIZE__:-false}
export __DEBUG__=${__DEBUG__:-false}
export __REBOOT__=${__REBOOT__:-false}

if [[ "$OS" != "$__OS_NAME__" ]]; then
  echo "'$OS' != '$__OS_NAME__'"
  exit 1
fi

if [[ "$OS_VERSION" != "$__OS_VERSION__" ]]; then
  echo "'$OS_VERSION' != '$__OS_VERSION__'"
  exit 1
fi

<% sun.list_helpers(Sunzistrano.root).each do |file| -%>
  source helpers/<%= file %>
<% end -%>

export ROLE_START=$(sun.start_time)
export REBOOT_RECIPE=false
export REBOOT_FORCE=false
export HOME=/home/$__OWNER_NAME__

export DEBIAN_FRONTEND=noninteractive
export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
export ARCH=$(dpkg --print-architecture)

trap sun.on_exit EXIT
sun.initialize

if [[ "$__DEBUG__" == 'trace' ]]; then
  set -x
fi
source roles/hook_before.sh
