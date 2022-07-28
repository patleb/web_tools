sun.whenever_update() {
  cd ${release_path}
  bin/whenever --update-crontab ${stage} --set "environment=${env}&application=${app}"
  cd - > /dev/null
}

sun.whenever_clear() {
  cd ${release_path}
  bin/whenever --clear-crontab ${stage}
  cd - > /dev/null
}
