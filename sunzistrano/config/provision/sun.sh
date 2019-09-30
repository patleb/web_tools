<% @sun.list_helpers(Sunzistrano.root).each do |file| %>
  source helpers/<%= file %>
<% end %>

sun.setup_progress() {
  if [[ -e "$HOME/$__MANIFEST_LOG__" ]]; then
    echo "Provisioning already started"
  else
    echo "New provisioning"
    touch "$HOME/$__MANIFEST_LOG__"
    mkdir "$HOME/$__MANIFEST_DIR__"
    mkdir "$HOME/$__DEFAULTS_DIR__"
  fi
  echo "Started at $(date '+%Y-%m-%d %H:%M:%S')"
}

sun.source_recipe() {
  local name=$1
  set +u; local id=$2; set -u
  if [[ ! "${id}" ]]; then
    id=$name
  fi
  if [[ "$__SPECIALIZE__" == true ]]; then
    if [[ -e "recipes/$name-specialize.sh" ]]; then
      name="$name-specialize"
      id="$id-specialize"
    fi
  fi
  RECIPE_ID="$id"
  if [[ "$name" == */all ]]; then
    source "recipes/$name.sh"
  elif [[ "$__ROLLBACK__" == true ]]; then
    if [[ -e "recipes/$name-rollback.sh" ]]; then
      source "recipes/$name-rollback.sh"
    fi
    sun.rollback "$id"
  elif sun.to_be_done "$id"; then
    local recipe_start=$(sun.start_time)
    source "recipes/hook_before.sh"
    source "recipes/$name.sh"
    cd $(sun.provision_path)
    source "recipes/hook_after.sh"
    sun.elapsed_time $recipe_start
    sun.done "$id"
  fi
  unset RECIPE_ID
}

sun.to_be_done() {
  if [[ ! $(grep -Fx "Done [$1]" "$HOME/$__MANIFEST_LOG__") ]]; then
    echo "Recipe [$1]"
    return 0
  else
    echo "Done [$1]"
    return 1
  fi
}

sun.done() {
  echo "Done [$1]" | tee -a "$HOME/$__MANIFEST_LOG__"
}

sun.start_time() {
  echo $(date -u +"%s")
}

sun.elapsed_time() {
  local start=$1
  local finish=$(date -u +"%s")
  local elapsed_time=$(($finish-$start))
  echo "$(($elapsed_time / 60)) minutes and $(($elapsed_time % 60)) seconds elapsed."
}

sun.ensure() {
  cd $(sun.provision_path)
  source roles/hook_ensure.sh
  sun.elapsed_time $ROLE_START
  set +u
  if [[ ! -z "$RECIPE_ID" ]]; then
    if [[ "$RECIPE_ID" != 'reboot' ]]; then
      echo ERROR
    fi
  fi
  set -u
  if [[ "$__DEBUG__" == false ]]; then
    rm -rf $(sun.provision_path)
  fi
}
trap sun.ensure EXIT

sun.rollback() {
  echo "Rollback [$1]"
  <%= Sh.delete_line! "$HOME/$__MANIFEST_LOG__", "Done [$1]", delimiter: '|', escape: false %>
}
