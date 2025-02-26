source /etc/os-release

export sun_setup_attributes_before=()
export sun_setup_attributes_after=()

sun.setup_commands() {
  export OS_NAME=$(sun.os_name)
  export OS_VERSION=$(sun.os_version)
  case "$OS_NAME" in
  ubuntu | linuxmint)
    export os_package_get='apt-get'
    export os_package_update='apt-get update'
    export os_package_upgrade='apt-get upgrade'
    export os_package_installed='dpkg -s'
    export os_package_lock='apt-mark hold'
    export os_package_unlock='apt-mark unhold'
    export os_package_add_repo='add-apt-repository'
  ;;
  *)
    echo "Unsupported OS"
    exit 1
  ;;
  esac
}

sun.setup_system_globals() {
  export TERM=linux
  export DEBIAN_FRONTEND=noninteractive
  export ARCH=$(dpkg --print-architecture)
  export CODE=${UBUNTU_CODENAME:-$VERSION_CODENAME}
  export HOME_WAS=$HOME
  export HOME=${1:-/home/<%= sun.ssh_user %>}
  sun.setup_system_locale
}

sun.setup_system_locale() {
  local locale=${locale:-en_US}
  local encoding="${locale}.UTF-8"
  export LOCALE=$locale
  export LANGUAGE=$encoding
  export LANG=$encoding
  export LC_CTYPE=$encoding
  export LC_ALL=$encoding
  export LC=$encoding
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

sun.os_name() { # PUBLIC
  echo ${ID:-$(hostnamectl | grep Operating | cut -d ':' -f2 | cut -d ' ' -f2)} | tr '[:upper:]' '[:lower:]'
}

sun.os_version() { # PUBLIC
  echo ${VERSION_ID:-$(hostnamectl | grep Operating | grep -o -E '[0-9]+' | head -n2 | paste -sd '.')}
}

sun.setup_attributes() {
  for before in "${sun_setup_attributes_before[@]}"; do
    $before
  done
  <% sun.attributes.each do |attribute, value| -%>
    export <%= attribute %>=<%= value.respond_to?(:call) ? value.call : value %>
  <% end -%>
  for after in "${sun_setup_attributes_after[@]}"; do
    $after
  done
}
