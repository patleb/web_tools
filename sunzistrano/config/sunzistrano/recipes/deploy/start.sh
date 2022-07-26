git_config_url=${git_config_url:-false}

desc 'Check that the repository is reachable'
if [[ "${git_config_url}" == true ]]; then
  git config --global url."https://github.com/".insteadOf git@github.com:
  git config --global url."https://".insteadOf git://
fi
git ls-remote ${repo_url} HEAD

desc 'Check shared and release directories exist'
mkdir -p "$shared_path" "$releases_path"
