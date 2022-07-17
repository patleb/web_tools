rm -f "/etc/nginx/ssl/${server_host}.server.key"
rm -f "/etc/nginx/ssl/${server_host}.server.crt"

source 'recipes/ssl/self_signed.sh'
