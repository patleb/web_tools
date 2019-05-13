export SERVER_NAME=<%= @sun.server %>
NGINX_CONF="/etc/nginx/sites-available/portainer"

docker run -d -p 127.0.0.1:9000:9000 \
  --restart always \
  --name portainer \
  -v '/var/run/docker.sock:/var/run/docker.sock' \
  -v "/opt/docker_data/portainer:/data" \
  portainer/portainer \
  --admin-password '<%= BCrypt::Password.create(@sun.deployer_password) %>'

sun.compile $NGINX_CONF
ln -nfs $NGINX_CONF /etc/nginx/sites-enabled/portainer

systemctl reload nginx

jwt=$(http :9000/api/auth username='admin' password='<%= @sun.deployer_password %>' --ignore-stdin)
jwt=$(echo $jwt | jq -r '.jwt')
http POST :9000/api/endpoints "Authorization: Bearer $jwt" Name="local" URL="unix:///var/run/docker.sock" --ignore-stdin
