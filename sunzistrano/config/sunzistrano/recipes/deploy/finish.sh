desc 'Clean up old releases'
touch $release_path
kept_releases=$(cat $revision_log | grep deployed | awk '{ print $2; }' | sed "s|^|${releases_path}/|")
releases=$(ls -dt ${releases_path}/*)
sun.remove_missing_files "$releases" "$kept_releases $release_path"
kept_releases=$(ls -dt ${releases_path}/* | head -n ${keep_releases})
releases=$(ls -dt ${releases_path}/*)
sun.remove_missing_files "$releases" "$kept_releases"
