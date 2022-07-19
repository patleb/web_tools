sun.source_recipe() {
  local name=$1
  set +u; local id=$2; set -u
  if [[ ! "${id}" ]]; then
    id=$name
  fi
  if [[ "${specialize}" == true ]]; then
    if [[ -e "recipes/$name-specialize.sh" ]]; then
      name="$name-specialize"
      id="$id-specialize"
    fi
  fi
  RECIPE_ID="$id"
  if [[ "${rollback}" == true ]]; then
    if [[ -e "recipes/$name-rollback.sh" ]]; then
      source "recipes/$name-rollback.sh"
    fi
    sun.rollback "$id"
  elif sun.to_be_done "$id"; then
    local recipe_start=$(sun.start_time)
    source "recipes/$name.sh"
    if [[ "$RECIPE_ID" != 'reboot' ]]; then
      cd "${bash_dir}"
      sun.elapsed_time $recipe_start
      sun.done "$id"
    fi
  fi
  unset RECIPE_ID
}

sun.to_be_done() {
  if [[ ! $(grep -Fx "Done [$1]" "${manifest_log}") ]]; then
    echo "Recipe [$1]"
    return 0
  else
    echo "Done [$1]"
    return 1
  fi
}

sun.done() {
  echo "Done [$1]" | tee -a "${manifest_log}"
}

sun.on_exit() {
  cd "${bash_dir}"
  sun.include "roles/${role}_ensure.sh"
  sun.elapsed_time $ROLE_START
  set +u
  if [[ ! -z "$RECIPE_ID" ]]; then
    if [[ "$RECIPE_ID" != 'reboot' ]]; then
      echo ERROR
    fi
  fi
  set -u
  if [[ "${debug}" == false ]]; then
    rm -rf "${bash_dir}"
  fi
}

sun.rollback() {
  echo "Rollback [$1]"
  # Sh.delete_line! "${manifest_log}", "Done [$1]", escape: false
  sed -rzi -- "s%(\n[^\n]*Done\ \[$1\][^\n]*|[^\n]*Done\ \[$1\][^\n]*\n)%%" ${manifest_log}
}
