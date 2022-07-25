if [[ "${env}" != 'vagrant' ]]; then
  sun.backup_copy '/etc/default/motd-news'
fi
sun.backup_compare '/etc/default/grub'
sun.backup_compare '/etc/sysctl.conf'
sun.backup_defaults '/etc/fstab'
# no sun.compare_defaults since there is a UUID
sun.backup_copy "/etc/logrotate.d/apt" 0440 root:root
sun.backup_copy "/etc/logrotate.d/rsyslog" 0440 root:root
