export nginx_maintenance_enable_before=()
export nginx_maintenance_enable_after=()
export nginx_maintenance_disable_before=()
export nginx_maintenance_disable_after=()

passenger.restart() {
  cd ${release_path}
  rbenv sudo passenger-config restart-app ${deploy_path} --ignore-app-not-running
  cd.back
}

nginx.maintenance_enable() {
  for before in "${nginx_maintenance_enable_before[@]}"; do
    $before
  done
  nginx.compile_503
  nginx.compile_stage 'maintenance'
  nginx.reload
  for after in "${nginx_maintenance_enable_after[@]}"; do
    $after
  done
}

nginx.maintenance_disable() {
  for before in "${nginx_maintenance_disable_before[@]}"; do
    $before
  done
  nginx.compile_stage
  nginx.reload
  for after in "${nginx_maintenance_disable_after[@]}"; do
    $after
  done
}

nginx.compile_stage() {
  set +u; local maintenance=$1; set -u
  if [[ "$maintenance" == maintenance ]]; then
    export nginx_early_return='return 503;'
  elif [[ ${passenger} == false ]]; then
    export nginx_early_return='return 200;'
  else
    export nginx_early_return=''
  fi
  local site_available="/etc/nginx/sites-available/${stage}"
  local site_enabled="/etc/nginx/sites-enabled/${stage}"
  sun.compile $site_available 0644 root:root
  if [[ ! -h $site_enabled ]]; then
    sudo ln -nfs $site_available $site_enabled
  fi
}

nginx.compile_503() {
  export nginx_maintenance_message=${nginx_maintenance_message:-"It'll be back shortly."}
  sun.compile "$shared_path/$(sun.flatten_path public/503.html)"
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
