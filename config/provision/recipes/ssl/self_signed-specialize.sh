rm -f "/etc/nginx/ssl/$__NGINX_DOMAIN__.server.key"
rm -f "/etc/nginx/ssl/$__NGINX_DOMAIN__.server.crt"

source 'recipes/ssl/self_signed.sh'
