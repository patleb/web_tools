sun.current_version() {
  local name=$1
  local manifest=$(sun.manifest_path $name)
  if [[ ! -s "$manifest" ]]; then
    case "$OS" in
    ubuntu)
      echo $(apt-cache policy $name | grep Candidate: | awk '{ print $2; }')
    ;;
    centos)
      echo $(yum --showduplicates list $name | tail -n1 | awk '{ print $2; }')
    ;;
    esac
  else
    echo $(tac "$manifest" | grep -m 1 '.')
  fi
}

sun.version_is_smaller() {
  case "$OS" in
  ubuntu)
    dpkg --compare-versions $1 lt $2
    return $?
  ;;
  centos)
    if [[ $(rpmdev-vercmp $1 $2 | awk '{ print $2; }') == '<' ]]; then
      return 0
    else
      return 1
    fi
  ;;
  esac
}

sun.os_name () {
  hostnamectl | grep Operating | cut -d ':' -f2 | cut -d ' ' -f2 | tr '[:upper:]' '[:lower:]'
}

sun.os_version () {
  hostnamectl | grep Operating | grep -o -E '[0-9]+' | head -n2 | paste -sd '.'
}

sun.manifest_path() {
  echo "$HOME/$__MANIFEST_DIR__/$1.log"
}

sun.metadata_path() {
  echo "$HOME/$__METADATA_DIR__/$1"
}
