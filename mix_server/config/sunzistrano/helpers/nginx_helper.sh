passenger.restart() {
  cd ${release_path}
  rbenv sudo passenger-config restart-app ${deploy_path} --ignore-app-not-running
  cd.back
}

nginx.recover() {
  nginx.stop
  nginx.kill
  nginx.start
}

nginx.start() {
  if nginx.check; then
    if sudo systemctl start nginx; then
      echo 'Nginx started'
    else
      echo.red 'Could not start Nginx.'
      exit 1
    fi
  fi
}

nginx.stop() {
  if sudo systemctl stop nginx; then
    echo 'Nginx stopped'
  else
    echo.red 'Could not stop Nginx.'
    exit 1
  fi
}

nginx.reload() {
  if nginx.check; then
    if sudo systemctl reload nginx; then
      echo 'Nginx reloaded'
    else
      echo.red 'Could not reload Nginx, trying start.'
      nginx.start
    fi
  fi
}

nginx.check() {
  if [[ $(sudo nginx -t | grep -c 'failed') -eq 0 ]]; then
    echo 'Config [OK]'
    return 0
  else
    echo.red 'Nginx configuration is invalid! (Make sure nginx configuration files are readable and correctly formated.)'
    exit 1
  fi
}

nginx.kill() {
  <%= Sh.kill('nginx', '-o') %>
}
