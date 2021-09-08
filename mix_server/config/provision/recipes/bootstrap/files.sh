if [[ "$__ENV__" != 'vagrant' ]]; then
  sun.backup_move '/etc/default/motd-news'
fi
sun.backup_compare '/etc/default/grub'
sun.backup_compare '/etc/sysctl.conf'
sun.backup_defaults '/etc/fstab'
# no sun.compare_defaults since there is a UUID
sun.backup_move "/etc/logrotate.d/apt" 0440 root:root
sun.backup_move "/etc/logrotate.d/rsyslog" 0440 root:root
