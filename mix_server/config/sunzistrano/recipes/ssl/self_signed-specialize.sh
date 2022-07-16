rm -f "/etc/nginx/ssl/$__SERVER_HOST__.server.key"
rm -f "/etc/nginx/ssl/$__SERVER_HOST__.server.crt"

source 'recipes/ssl/self_signed.sh'
