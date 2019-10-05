rm -f "/etc/nginx/ssl/$__NGINX_DOMAIN__.ca.key"
rm -f "/etc/nginx/ssl/$__NGINX_DOMAIN__.ca.crt"

source 'recipes/ssl/ca.sh'
