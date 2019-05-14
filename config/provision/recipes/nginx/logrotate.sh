export DEPLOYER_NAME=<%= @sun.deployer_name %>

sun.backup_compile '/etc/logrotate.d/nginx'
chown $DEPLOYER_NAME:adm /var/log/nginx
