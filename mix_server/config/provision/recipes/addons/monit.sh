sun.install "monit"

# TODO https://medium.com/@hack4mer/how-to-fix-perl-warning-setting-locale-failed-errors-on-linux-844081311469
sun.backup_compare "/etc/monit/monitrc"

systemctl enable monit
systemctl start monit

# configured with ext_capistrano gem
