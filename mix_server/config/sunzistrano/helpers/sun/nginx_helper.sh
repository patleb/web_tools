sun.passenger_restart() {
  cd ${release_path}
  rbenv sudo passenger-config restart-app ${deploy_path} --ignore-app-not-running
  cd.back
}

sun.nginx_recover() {
  sun.nginx_stop
  sun.nginx_kill
  sun.nginx_start
}

sun.nginx_start() {
  if sun.nginx_check; then
    if sudo systemctl start nginx; then
      echo 'Nginx started'
    else
      echo.red 'Could not start Nginx.'
      exit 1
    fi
  fi
}

sun.nginx_stop() {
  if sudo systemctl stop nginx; then
    echo 'Nginx stopped'
  else
    echo.red 'Could not stop Nginx.'
    exit 1
  fi
}

sun.nginx_reload() {
  if sun.nginx_check; then
    if sudo systemctl reload nginx; then
      echo 'Nginx reloaded'
    else
      echo.red 'Could not reload Nginx, trying start.'
      sun.nginx_start
    fi
  fi
}

sun.nginx_check() {
  if [[ $(sudo nginx -t | grep -c 'failed') -eq 0 ]]; then
    echo 'Config [OK]'
    return 0
  else
    echo.red 'Nginx configuration is invalid! (Make sure nginx configuration files are readable and correctly formated.)'
    exit 1
  fi
}

sun.nginx_kill() {
  <%= Sh.kill('nginx', '-o') %>
}
