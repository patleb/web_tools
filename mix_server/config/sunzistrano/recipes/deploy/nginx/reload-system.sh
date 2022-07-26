desc 'Reload nginx service'
if sun.nginx_check; then
  sun.nginx_reload
fi
