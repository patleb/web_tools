sun.setup_commands() {
  export OS_NAME=$(sun.os_name)
  export OS_VERSION=$(sun.os_version)
  case "$OS_NAME" in
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
}

sun.setup_system_globals() {
  source /etc/os-release
  export TERM=linux
  export DEBIAN_FRONTEND=noninteractive
  export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
  export ARCH=$(dpkg --print-architecture)
  export HOME_WAS=$HOME
  export HOME=${1:-/home/<%= sun.ssh_user %>}
}

sun.check_os() {
  if [[ "$OS_NAME" != "${os_name}" ]]; then
    echo "'$OS_NAME' != '${os_name}'"
    exit 1
  fi

  if [[ "$OS_VERSION" != "${os_version}" ]]; then
    echo "'$OS_VERSION' != '${os_version}'"
    exit 1
  fi
}

sun.os_name() {
  hostnamectl | grep Operating | cut -d ':' -f2 | cut -d ' ' -f2 | tr '[:upper:]' '[:lower:]'
}

sun.os_version() {
  hostnamectl | grep Operating | grep -o -E '[0-9]+' | head -n2 | paste -sd '.'
}

sun.setup_attributes() {
  <% sun.attributes.each do |attribute, value| -%>
    export <%= attribute %>=<%= value.respond_to?(:call) ? value.call : value %>
  <% end -%>
}
