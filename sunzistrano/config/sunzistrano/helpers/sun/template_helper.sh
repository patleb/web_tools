sun.upgrade_copy() {
  sun.remove_defaults $1
  sun.backup_copy $@
}

sun.upgrade_compile() {
  sun.remove_defaults $1
  sun.backup_compile $@
}

sun.upgrade_compare() {
  sun.remove_defaults $1
  sun.backup_compare $1
}

sun.upgrade_defaults() {
  sun.remove_defaults $1
  sun.backup_defaults $1
}

sun.backup_copy() {
  sun.backup_compare $1
  sun.copy $@
}

sun.backup_compile() {
  sun.backup_compare $1
  sun.compile $@
}

sun.backup_compare() {
  sun.backup_defaults $1
  sun.compare_defaults $1
}

sun.backup_defaults() {
  local bkp="$(sun.defaults_path $1)"
  if [[ -s $bkp ]]; then
    echo "$1 already copied"
  else
    cp "$1" $bkp
  fi
}

sun.remove_defaults() {
  local bkp="$(sun.defaults_path $1)"
  rm -f $bkp
}

sun.copy() {
  local dst="$1"
  if [[ $# == 1 ]]; then
    cp "$(sun.template_path $dst)" $dst
  else
    sun.sudo "cp $(sun.template_path $dst) $dst"
  fi
  sun.permit $@
  echo "Copied \"$@\""
}

sun.compile() {
  local dst="$1"
  local src="$(sun.template_path $dst).esh"
  if [[ ! -f $src ]]; then
    echo "template: $src: No such file"
    exit 1
  fi
  local tmp=$(mktemp)
  echo 'cat <<EOF_COMPILE' > $tmp
  cat $src                 >> $tmp
  echo ''                  >> $tmp
  echo 'EOF_COMPILE'       >> $tmp
  if [[ $# == 1 ]]; then
    bash -e -u +H $tmp > $dst
  else
    sun.sudo "bash -e -u +H $tmp > $dst"
    sun.permit $@
  fi
  sudo rm -f $tmp
  echo "Compiled \"$@\""
}

sun.compare_defaults() {
  local bkp="$(sun.defaults_path $1)"
  local ref="$(sun.template_path $1).ref"
  if [[ ! -f $ref ]]; then
    echo "defaults: $ref: No such file"
    exit 1
  fi
  local diff="$(diff --strip-trailing-cr --ignore-blank-lines --ignore-space-change $bkp $ref)"
  if [[ ! $diff ]]; then
    return 0
  else
    echo $1
    echo -e $diff
    exit 1
  fi
}

sun.defaults_path() {
  echo "${defaults_dir}/$(sun.flatten_path $1)"
}

sun.template_path() {
  local base="${bash_dir}/files/$(echo "$1" | sed 's|^/||')"
  local type="$base.$OS_NAME"
  local type_version="$type.$OS_VERSION"
  if [[ -e "$type_version" ]] || [[ -e "$type_version.esh" ]] || [[ -e "$type_version.ref" ]]; then
    echo "$type_version"
    return
  fi
  if [[ -e "$type" ]] || [[ -e "$type.esh" ]] || [[ -e "$type.ref" ]]; then
    echo "$type"
    return
  fi
  echo $base
}

sun.permit() {
  local dst="$1"
  set +u; local permissions=$2; set -u
  if [[ "${permissions}" ]]; then
    sudo chmod $permissions $dst
  fi
  set +u; local owner=$3; set -u
  if [[ "${owner}" ]]; then
    sudo chown $owner $dst
  fi
}

sun.sudo() {
  sudo -E bash -c -e -u "$@"
}
