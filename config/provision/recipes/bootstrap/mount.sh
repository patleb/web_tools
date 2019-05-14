sun.backup_compare '/etc/default/grub'
sun.backup_compare '/etc/sysctl.conf'
sun.backup_defaults '/etc/fstab'
# no sun.compare_defaults since there is a UUID
<%= Sh.sub! '/etc/fstab', 'defaults', 'defaults,noatime' %>

mount -o remount /
