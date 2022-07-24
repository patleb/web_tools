desc 'Clone the repo to the cache'
if [[ -f "${repo_path}/HEAD" ]]; then
  echo "Mirror exists at ${repo_path}"
elif [[ "${git_shallow_clone}" != false ]]; then
  git clone --mirror --depth ${git_shallow_clone} --no-single-branch ${repo_url} ${repo_path}
else
  git clone --mirror ${repo_url} ${repo_path}
fi

cd ${repo_path}

desc 'Update the repo mirror to reflect the origin state'
git remote set-url origin ${repo_url}
if [[ "${git_shallow_clone}" != false ]]; then
  git fetch --depth ${git_shallow_clone} origin ${branch}
else
  git remote update --prune
fi
if [[ "${git_verify_commit}" != false ]]; then
  git verify-commit ${revision}
fi

desc 'Copy repo to releases'
mkdir -p "$release_path"
git archive ${branch} | tar -x -f - -C $release_path

desc 'Place a REVISION file with the current revision SHA in the current release path'
echo "${revision}" > "$release_path/REVISION"

desc 'Symlink linked directories'
for linked_dir in ${linked_dirs}; do
  target="$release_path/$linked_dir"
  source="$shared_path/$(sun.flatten_path $linked_dir)"
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
  if [[ ! -L $target ]]; then
    if [[ -f $target ]]; then
      rm $target
    fi
    ln -s $source $target
  fi
done

cd - > /dev/null
