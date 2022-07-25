sun.install "sysstat"

sun.backup_copy '/etc/default/sysstat'

systemctl enable sysstat
systemctl start sysstat
