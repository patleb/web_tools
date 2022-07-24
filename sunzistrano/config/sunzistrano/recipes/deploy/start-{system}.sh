desc 'Check that the repository is reachable'
if [[ "${system}" == true ]]; then
  git config --global url."https://github.com/".insteadOf git@github.com:
  git config --global url."https://".insteadOf git://
fi
git ls-remote ${repo_url} HEAD

desc 'Check shared and release directories exist'
mkdir -p "$shared_path" "$releases_path"

desc 'Check directories to be linked exist in shared'
for linked_dir in ${linked_dirs}; do
  mkdir -p "$shared_path/$(sun.flatten_path $linked_dir)"
done

if [[ "${system}" == false ]]; then
  desc 'Check files to be linked exist in shared'
  for linked_file in ${linked_files}; do
    linked_file="$shared_path/$(sun.flatten_path $linked_file)"
    if [[ ! -f $linked_file ]]; then
      echo.red "$linked_file doesn't exist"
      exit 1
    fi
  done
fi
