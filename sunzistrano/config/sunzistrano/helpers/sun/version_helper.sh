sun.major_version() {
  local version="$1"
  IFS='.' read -ra version <<< "$version"
  echo "$(echo ${version[0]} | sed -r 's/^([0-9]+).*/\1/')"
}

sun.available_version() {
  local name=$1
  echo $(apt-cache policy $name | grep Candidate: | awk '{ print $2; }')
}

sun.installed_version() {
  local name=$1
  echo $(apt-cache policy $name | grep Installed: | awk '{ print $2; }')
}

sun.manifest_path() {
  echo "${manifest_dir}/$1.log"
}

sun.metadata_path() {
  echo "${metadata_dir}/$1"
}
