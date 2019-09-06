 # TODO hide htop output
DEPLOYER_NAME=<%= @sun.deployer_name %>
DEPLOYER_PATH=/home/$DEPLOYER_NAME
CONFIG_PATH="$DEPLOYER_PATH/.config/htop/htoprc"

sun.install "htop"
sudo su - $DEPLOYER_NAME << 'EOF'
  bash --rcfile ~/.bashrc -ci 'htop > /dev/null 2>&1'
EOF

sun.backup_defaults $CONFIG_PATH
<%= Sh.sub! '$CONFIG_PATH', 'hide_userland_threads=0', 'hide_userland_threads=1' %>
