sun.nginx_reload() {
  if sun.nginx_check; then
    if sudo systemctl reload nginx; then
      echo 'Nginx reloaded'
    else
      echo.red 'Could not reload Nginx, trying start.'
      sudo systemctl start nginx
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
