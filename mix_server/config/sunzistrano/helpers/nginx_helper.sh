export nginx_maintenance_enable_before=()
export nginx_maintenance_enable_after=()
export nginx_maintenance_disable_before=()
export nginx_maintenance_disable_after=()

# %{exec "/usr/bin/sudo -u deployer -H sh -c '/home/deployer/.rbenv/bin/#{passenger_command}'"}
passenger.restart() { # PUBLIC
  cd ${release_path}
  rbenv sudo passenger-config restart-app ${deploy_path} --ignore-app-not-running
  cd.back
}

nginx.maintenance_enable() { # PUBLIC
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

nginx.maintenance_disable() { # PUBLIC
  for before in "${nginx_maintenance_disable_before[@]}"; do
    $before
  done
  nginx.compile_stage
  nginx.reload
  for after in "${nginx_maintenance_disable_after[@]}"; do
    $after
  done
}

nginx.copy_system_conf() { # PUBLIC
  sun.copy '/etc/nginx/nginx.conf' 0644 root:root
}

nginx.compile_stage() { # PUBLIC
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

nginx.compile_503() { # PUBLIC
  export message_503=${message_503:-''}
  sun.compile "$shared_path/$(sun.flatten_path public/503.html)"
}

nginx.recover() { # PUBLIC
  nginx.stop
  nginx.kill
  nginx.start
}

nginx.start() { # PUBLIC
  if nginx.check; then
    if sudo systemctl start nginx; then
      echo 'Nginx started'
    else
      echo.red 'Could not start Nginx.'
      exit 1
    fi
  fi
}

nginx.stop() { # PUBLIC
  if sudo systemctl stop nginx; then
    echo 'Nginx stopped'
  else
    echo.red 'Could not stop Nginx.'
    exit 1
  fi
}

nginx.reload() { # PUBLIC
  if nginx.check; then
    if sudo systemctl reload nginx; then
      echo 'Nginx reloaded'
    else
      echo.red 'Could not reload Nginx, trying start.'
      nginx.start
    fi
  fi
}

nginx.check() { # PUBLIC
  if [[ $(sudo nginx -t 2>&1 | grep -c 'failed') -eq 0 ]]; then
    echo 'Config [OK]'
    return 0
  else
    echo.red 'Nginx configuration is invalid! (Make sure nginx configuration files are readable and correctly formated.)'
    exit 1
  fi
}

nginx.kill() { # PUBLIC
  <%= Sh.kill('nginx', '-o') %>
}
