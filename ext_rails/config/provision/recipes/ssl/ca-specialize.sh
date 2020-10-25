rm -f "/etc/nginx/ssl/$__SERVER_HOST__.ca.key"
rm -f "/etc/nginx/ssl/$__SERVER_HOST__.ca.crt"

source 'recipes/ssl/ca.sh'
