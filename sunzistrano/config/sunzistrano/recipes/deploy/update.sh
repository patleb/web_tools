desc 'Clone the repo to the cache'
if [[ "${git_shallow_clone}" == true ]]; then
  git_shallow_clone="--depth 1"
fi
if [[ -f "${repo_path}/HEAD" ]]; then
  echo "Mirror exists at ${repo_path}"
elif [[ "${git_shallow_clone}" != false ]]; then
  git clone --mirror ${git_shallow_clone} --no-single-branch ${repo_url} ${repo_path}
else
  git clone --mirror ${repo_url} ${repo_path}
fi

cd ${repo_path}

if [[ "${git_submodules}" == true ]]; then
  desc 'Update the repo submodules'
  if [[ "${git_shallow_clone}" != false ]]; then
    git submodule update --init --recursive ${git_shallow_clone} --no-single-branch
  else
    git submodule update --init --recursive
  fi
fi

desc 'Update the repo mirror to reflect the origin state'
git remote set-url origin ${repo_url}
if [[ "${git_shallow_clone}" != false ]]; then
  git fetch ${git_shallow_clone} origin ${branch}
else
  git remote update --prune
fi
if [[ "${git_verify_commit}" != false ]]; then
  git verify-commit ${revision}
fi

desc 'Check the current revision against the clone'
if [[ "${revision}" != "$(git rev-parse ${branch})" ]]; then
  echo.failure 'current and cloned revisions differ'
  exit 1
fi

desc 'Copy repo to releases'
mkdir -p "$release_path"
git archive ${branch} | tar -x -f - -C $release_path

cd.back

desc 'Place a REVISION file with the current revision SHA in the current release path'
echo "${revision}" > "$release_path/REVISION"

desc 'Symlink linked directories'
for linked_dir in ${linked_dirs}; do
  target="$release_path/$linked_dir"
  source="$shared_path/$(sun.flatten_path $linked_dir)"
  mkdir -p $source
  if [[ ! -L $target ]]; then
    if [[ -d $target ]]; then
      rm -rf $target
    fi
    ln -s $source $target
  fi
done

desc 'Symlink linked files'
for linked_file in ${linked_files}; do
  target="$release_path/$linked_file"
  source="$shared_path/$(sun.flatten_path $linked_file)"
  if [[ ! -f $source ]]; then
    echo.red "$source doesn't exist"
    exit 1
  fi
  if [[ ! -L $target ]]; then
    if [[ -f $target ]]; then
      rm $target
    fi
    ln -s $source $target
  fi
done
