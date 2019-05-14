sun.install "monit"

sun.backup_compare "/etc/monit/monitrc"

systemctl start monit

# configured with ext_capistrano gem
