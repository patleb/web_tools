git.dir() {
  local owner=$1 repo=$2
  echo "$HOME/github/$owner/$repo"
}

git.dir.latest() {
  local release=$(ls -td -- */ | head -n 1 | cut -d'/' -f1)
  git.dir.release $1 $2 $release
}

git.dir.release() {
  local owner=$1 repo=$2 release $3
  local root_dir = "$HOME/github/${owner}/${repo}-releases"
  cd $root_dir
  cd.back
  echo "$root_dir/$release"
}

git.clone() {
  local owner=$1 repo=$2
  local root_dir = $HOME/github/$owner
  mkdir -p $root_dir
  cd $root_dir
  git clone "https://github.com/${owner}/${repo}.git"
  cd $repo
}

git.clone.latest() {
  local owner=$1 repo=$2
  local url=$(curl -Ls -o /dev/null -w %{url_effective} "https://github.com/${owner}/${repo}/releases/latest")
  local tag=$(basename $url)
  local root_dir = "$HOME/github/${owner}/${repo}-releases"
  mkdir -p $root_dir
  cd $root_dir
  if [[ -d "$root_dir/$tag" ]]; then
    echo.warning "Already at the latest [$tag]"
    cd $tag
    return 1
  else
    git clone -b $tag --depth=1 -- "https://github.com/${owner}/${repo}.git" $tag
    cd $tag
    return 0
  fi
}
