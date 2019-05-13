<% @sun.role_helpers(Sunzistrano.root).each do |file| %>
  source helpers/<%= file %>
<% end %>

sun.setup_progress() {
  if [[ -e "$HOME/<%= @sun.MANIFEST_LOG %>" ]]; then
    echo "Provisioning already started"
  else
    echo "New provisioning"
    touch "$HOME/<%= @sun.MANIFEST_LOG %>"
    mkdir "$HOME/<%= @sun.MANIFEST_DIR %>"
    mkdir "$HOME/<%= @sun.DEFAULTS_DIR %>"
  fi
  echo "Started at $(date '+%Y-%m-%d %H:%M:%S')"
}

sun.source_recipe() {
  local name=$1
  set +u; local id=$2; set -u
  if [[ ! "${id}" ]]; then
    id=$name
  fi
  RECIPE_ID="$id"
  if [[ "$name" == */<%= @sun.LIST_NAME %> ]]; then
    source "recipes/$name.sh"
  elif [[ "<%= @sun.rollback.to_b %>" == true ]]; then
    name=$(echo "$name" | sed -r 's/<%= Sh.sed_escape @sun.VARIABLES %>/-rollback/g')
    if [[ -e "recipes/$name.sh" ]]; then
      source "recipes/$name.sh"
    else
      source "recipes/$name-rollback.sh"
    fi
    sun.rollback "$id"
  elif sun.to_be_done "$id"; then
    local recipe_start=$(sun.start_time)
    source "recipes/hook_before.sh"
    source "recipes/$name.sh"
    cd $(sun.deploy_path)
    source "recipes/hook_after.sh"
    sun.elapsed_time $recipe_start
    sun.done "$id"
  fi
  unset RECIPE_ID
}

sun.to_be_done() {
  if [[ ! $(grep -Fx "<%= @sun.DONE %>" "$HOME/<%= @sun.MANIFEST_LOG %>") ]]; then
    echo "Recipe [<%= @sun.DONE_ARG %>]"
    return 0
  else
    echo "<%= @sun.DONE %>"
    return 1
  fi
}

sun.done() {
  echo "<%= @sun.DONE %>" | tee -a "$HOME/<%= @sun.MANIFEST_LOG %>"
}

sun.rollback() {
  echo "Rollback [<%= @sun.DONE_ARG %>]"
  <%= Sh.delete_line! "$HOME/#{@sun.MANIFEST_LOG}", %{"#{@sun.DONE}"} %>
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
  cd $(sun.deploy_path)
  source roles/hook_ensure.sh
  sun.elapsed_time $ROLE_START
  <%= "rm -rf ~/#{@sun.DEPLOY_DIR}" unless @sun.debug %>
}
trap sun.ensure EXIT
