sun.current_version() {
  local name=$1
  local manifest=$(sun.manifest_path $name)
  if [[ ! -s "$manifest" ]]; then
    echo $(apt-cache policy $name | grep Candidate: | awk '{ print $2; }')
  else
    echo $(tac "$manifest" | grep -m 1 '.')
  fi
}

sun.version_is_smaller() {
  dpkg --compare-versions $1 lt $2
  return $?
}

sun.manifest_path() {
  echo "$HOME/<%= @sun.MANIFEST_DIR %>/$1.log"
}
