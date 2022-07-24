desc 'Clean up old releases'
kept_releases=($(ls -dt ${releases_path}/* | head -n ${keep_releases}))
releases=($(ls -dt ${releases_path}/*))
for release in "${releases[@]}"; do
  remove=true
  for kept in "${kept_releases[@]}"; do
    if [[ $release == $kept ]]; then
      remove=false
    fi
  done
  if [[ $remove == true ]]; then
    rm -rf $release
  fi
done
