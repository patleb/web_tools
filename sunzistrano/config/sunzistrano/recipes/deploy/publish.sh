echo 'Symlink release to current'
current_link="$releases_path/current"
ln -s $release_path $current_link
mv $current_link ${deploy_path}
