whenever.update() { # PUBLIC
  if [[ -f "$(nginx.maintenance_file)" ]]; then
    echo.warning "Nginx in maintenance: skipped whenever.update"
  else
    cd ${release_path}
    bin/whenever --update-crontab ${stage} --set "environment=${env}&application=${app}"
    cd.back
  fi
}
nginx_maintenance_disable_after+=('whenever.update')

whenever.clear() { # PUBLIC
  cd ${release_path}
  bin/whenever --clear-crontab ${stage}
  cd.back
}
nginx_maintenance_enable_before+=('whenever.clear')
