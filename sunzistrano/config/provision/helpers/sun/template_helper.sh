sun.move() {
  mv "$(sun.template_path $1)" $1
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

# bundle exec sun download vagrant system <path> --dev --saved
sun.compare_defaults() {
  local bkp="$(sun.defaults_path $1)"
  local ref="$(sun.template_path $1).ref"
  if [[ ! -s $ref ]]; then
    echo "defaults: $ref: No such file"
    exit 1
  fi
  local diff="$(diff --ignore-trailing-space --strip-trailing-cr $bkp $ref)"
  if [[ ! $diff ]]; then
    return 0
  else
    echo $1
    echo -e $diff
    exit 1
  fi
}

sun.defaults_path() {
  echo "$HOME/<%= @sun.DEFAULTS_DIR %>/$(echo "$1" | sed 's|/|~|g')"
}

sun.template_path() {
  echo "$(sun.deploy_path)/files/$(echo "$1" | sed 's|^/||')"
}
