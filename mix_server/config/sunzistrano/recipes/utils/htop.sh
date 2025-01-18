DEPLOYER_PATH=/home/deployer

sun.install "htop"
bash --rcfile ~/.bashrc -ci 'htop > /dev/null 2>&1' > /dev/null 2>&1
sudo su - deployer << 'EOF'
  set -eu
  bash --rcfile ~/.bashrc -ci 'htop > /dev/null 2>&1' > /dev/null 2>&1
EOF

sun.backup_defaults "$HOME/.config/htop/htoprc"
sun.backup_defaults "$DEPLOYER_PATH/.config/htop/htoprc"
<%= Sh.sub! '$HOME/.config/htop/htoprc', 'hide_userland_threads=0', 'hide_userland_threads=1' %>
<%= Sh.sub! '$DEPLOYER_PATH/.config/htop/htoprc', 'hide_userland_threads=0', 'hide_userland_threads=1' %>
chown -R ${owner_name}:${owner_name} "$HOME/.config"
