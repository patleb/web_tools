echo 'Check that the repository is reachable'
git ls-remote ${repo_url} HEAD

echo 'Check shared and release directories exist'
mkdir -p "$shared_path" "$releases_path"

echo 'Check directories to be linked exist in shared'
for linked_dir in ${linked_dirs}; do
  mkdir -p "$shared_path/$(sun.flatten_path $linked_dir)"
done

if [[ "${system}" == false ]]; then
  echo 'Check files to be linked exist in shared'
  for linked_file in ${linked_files}; do
    linked_file="$shared_path/$(sun.flatten_path $linked_file)"
    if [[ ! -f $linked_file ]]; then
      echo "$linked_file doesn't exist"
      exit 1
    fi
  done
fi
