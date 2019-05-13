DEPLOYER_NAME=<%= @sun.deployer_name %>
DEPLOYER_HTPASSWD=<%= @sun.deployer_password %>

echo -n "$DEPLOYER_NAME:" >> /etc/nginx/.htpasswd
openssl passwd -apr1 "$DEPLOYER_HTPASSWD" >> /etc/nginx/.htpasswd
