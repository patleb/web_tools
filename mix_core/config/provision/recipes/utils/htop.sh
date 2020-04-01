DEPLOYER_PATH=/home/$__DEPLOYER_NAME__
CONFIG_PATH="$DEPLOYER_PATH/.config/htop/htoprc"

sun.install "htop"
sudo su - $__DEPLOYER_NAME__ << 'EOF'
  bash --rcfile ~/.bashrc -ci 'htop > /dev/null 2>&1'
EOF

sun.backup_defaults $CONFIG_PATH
<%= Sh.sub! '$CONFIG_PATH', 'hide_userland_threads=0', 'hide_userland_threads=1' %>
<%= Sh.sub!('$CONFIG_PATH', 'color_scheme=0', 'color_scheme=6') if sun.os.ubuntu? %>
