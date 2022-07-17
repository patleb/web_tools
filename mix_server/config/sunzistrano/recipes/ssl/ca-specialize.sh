rm -f "/etc/nginx/ssl/${server_host}.ca.key"
rm -f "/etc/nginx/ssl/${server_host}.ca.crt"

source 'recipes/ssl/ca.sh'
