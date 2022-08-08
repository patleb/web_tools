whenever.update() {
  cd ${release_path}
  bin/whenever --update-crontab ${stage} --set "environment=${env}&application=${app}"
  cd.back
}

whenever.clear() {
  cd ${release_path}
  bin/whenever --clear-crontab ${stage}
  cd.back
}
