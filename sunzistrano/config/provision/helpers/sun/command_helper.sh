sun.install() {
  if sun.installed "$@"; then
    echo "$@ already installed"
  else
    sun.mute "apt-get -y install $@"
  fi
}

sun.installed() {
  dpkg -s $@ >/dev/null 2>&1
  return $?
}

sun.update() {
  sun.mute "apt update"
}

sun.mute() {
  echo "Running \"$@\""
  `$@ >/dev/null 2>&1`
  return $?
}

sun.deploy_path() {
  echo "$HOME/<%= @sun.DEPLOY_DIR %>"
}
