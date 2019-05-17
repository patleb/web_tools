sun.install() {
  if sun.installed "$@"; then
    echo "$@ already installed"
  else
    sun.mute "$os_package_get -y install $@"
  fi
}

sun.installed() {
  $os_package_installed $@ >/dev/null 2>&1
  return $?
}

sun.update() {
  sun.mute "$os_package_update"
}

sun.upgrade() {
  $os_package_upgrade
}

sun.mute() {
  echo "Running \"$@\""
  `$@ >/dev/null 2>&1`
  return $?
}

sun.deploy_path() {
  echo "$HOME/<%= @sun.DEPLOY_DIR %>"
}
