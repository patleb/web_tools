sun.backup_compare '/etc/default/grub'
sun.backup_compare '/etc/sysctl.conf'
sun.backup_defaults '/etc/fstab'
# no sun.compare_defaults since there is a UUID
sun.backup_move "/etc/logrotate.d/apt"
sun.backup_move "/etc/logrotate.d/rsyslog"
