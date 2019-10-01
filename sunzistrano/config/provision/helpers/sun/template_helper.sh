sun.backup_move() {
  sun.backup_compare $1
  sun.move $@
}

sun.move() {
  local dst="$1"
  mv "$(sun.template_path $dst)" $dst
  set +u; local permissions=$2; set -u
  if [[ "${permissions}" ]]; then
    chmod $permissions $dst
  fi
  set +u; local owner=$3; set -u
  if [[ "${owner}" ]]; then
    chown $owner $dst
  fi
}

sun.backup_compile() {
  sun.backup_compare $1
  sun.compile $@
}

sun.compile() {
  local dst="$1"
  local src="$(sun.template_path $dst).esh"
  if [[ ! -s $src ]]; then
    echo "template: $src: No such file"
    exit 1
  fi
  local tmp=$(mktemp)
  echo 'cat <<EOF_COMPILE' > $tmp
  cat $src                 >> $tmp
  echo 'EOF_COMPILE'       >> $tmp
  bash -u $tmp > $dst
  rm -f $tmp
  set +u; local permissions=$2; set -u
  if [[ "${permissions}" ]]; then
    chmod $permissions $dst
  fi
  set +u; local owner=$3; set -u
  if [[ "${owner}" ]]; then
    chown $owner $dst
  fi
  echo "Compiled \"$@\""
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

# bundle exec sun download vagrant system <path> --dev --saved
sun.compare_defaults() {
  local bkp="$(sun.defaults_path $1)"
  local ref="$(sun.template_path $1).ref"
  if [[ ! -s $ref ]]; then
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
  echo "$HOME/$__DEFAULTS_DIR__/$(echo "$1" | sed 's|/|~|g')"
}

sun.template_path() {
  local base="$(sun.provision_path)/files/$(echo "$1" | sed 's|^/||')"
  local type="$base.$__OS_NAME__"
  if [[ -e "$type" ]] || [[ -e "$type.esh" ]] || [[ -e "$type.ref" ]]; then
    echo "$type"
    return
  fi
  type="$base.$__ENV__"
  if [[ -e "$type" ]] || [[ -e "$type.esh" ]] || [[ -e "$type.ref" ]]; then
    echo "$type"
    return
  fi
  echo $base
}
