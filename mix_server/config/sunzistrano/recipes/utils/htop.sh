DEPLOYER_PATH=/home/$__DEPLOYER_NAME__

sun.install "htop"
bash --rcfile ~/.bashrc -ci 'htop > /dev/null 2>&1'
sudo su - $__DEPLOYER_NAME__ << 'EOF'
  bash --rcfile ~/.bashrc -ci 'htop > /dev/null 2>&1'
EOF

sun.backup_defaults "$HOME/.config/htop/htoprc"
sun.backup_defaults "$DEPLOYER_PATH/.config/htop/htoprc"
<%= Sh.sub! '$HOME/.config/htop/htoprc', 'hide_userland_threads=0', 'hide_userland_threads=1' %>
<%= Sh.sub! '$DEPLOYER_PATH/.config/htop/htoprc', 'hide_userland_threads=0', 'hide_userland_threads=1' %>
chown -R $__OWNER_NAME__:$__OWNER_NAME__ "$HOME/.config"
