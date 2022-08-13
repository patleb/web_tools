sun.install() {
  if sun.installed "$@"; then
    echo "$@ already installed"
  else
    sun.mute "sudo $os_package_get -y install $@"
  fi
}

sun.installed() {
  $os_package_installed $@ >/dev/null 2>&1
  return $?
}

sun.remove() {
  sun.mute "$os_package_get -y remove $@"
}

sun.update() {
  sun.mute "$os_package_update"
}

sun.upgrade() {
  if [[ $# -eq 0 ]]; then
    $os_package_upgrade
  else
    sun.mute "$os_package_get -y install $@"
  fi
}

sun.lock() {
  $os_package_lock $@
}

sun.unlock() {
  $os_package_unlock $@
}

sun.mute() {
  echo "Running \"$@\""
  `$@ >/dev/null 2>&1`
  return $?
}
