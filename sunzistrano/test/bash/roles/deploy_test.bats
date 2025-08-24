source 'sunzistrano/test/bash/spec_helper.sh'

setup() {
  sun.test_setup 'deploy'
  cd "$ROOT/sunzistrano/config/sunzistrano"
  linked_dirs='tmp/logs tmp/pids'
  linked_files='public/503.html public/robots.txt'
  keep_releases=3
  dir_logs="$shared_path/$(sun.flatten_path tmp/logs)"
  dir_pids="$shared_path/$(sun.flatten_path tmp/pids)"
  file_503="$shared_path/$(sun.flatten_path public/503.html)"
  file_robots="$shared_path/$(sun.flatten_path public/robots.txt)"
  system=true
}

teardown() {
  sun.test_teardown
}

@test 'deploy/start.sh recipe' {
  run source 'recipes/deploy/start.sh'
  assert_dir_exists $shared_path
  assert_dir_exists $releases_path
  assert_success
}

@test 'deploy/update.sh recipe' {
  source 'recipes/deploy/start.sh'
  touch $file_503
  touch $file_robots
  run source 'recipes/deploy/update.sh'
  assert_file_exists "${repo_path}/HEAD"
  assert_file_exists "$release_path/README.md"
  assert_file_exists "$release_path/REVISION"
  assert_file_exists "$release_path/REVISION_TIME"
  assert_symlink_to $dir_logs "$release_path/tmp/logs"
  assert_symlink_to $dir_pids "$release_path/tmp/pids"
  assert_symlink_to $file_503 "$release_path/public/503.html"
  assert_symlink_to $file_robots "$release_path/public/robots.txt"
  assert_success
}

@test 'deploy/publish.sh recipe' {
  source 'recipes/deploy/start.sh'
  touch $file_503
  touch $file_robots
  source 'recipes/deploy/update.sh'
  run source 'recipes/deploy/publish.sh'
  assert_symlink_to $release_path $current_path
  assert_success
}

@test 'deploy/finish.sh recipe' {
  source 'recipes/deploy/start.sh'
  touch $file_503
  touch $file_robots
  echo '' > $revision_log
  for i in {1..4}; do
    dir_i="$releases_path/$i"
    if [[ -d $dir_i ]]; then
      rmdir $dir_i
    fi
    mkdir $dir_i
    sleep 0.001
    touch $dir_i
    if (( $i != 4 )); then
      echo "deployed $i" >> $revision_log
    fi
  done
  source 'recipes/deploy/update.sh'
  source 'recipes/deploy/publish.sh'
  run source 'recipes/deploy/finish.sh'
  assert_dir_exists "$releases_path/2"
  assert_dir_exists "$releases_path/3"
  assert_dir_exists "$release_path"
  assert_equal $(ls -d ${releases_path}/* | wc -l) 3
  assert_success
}
