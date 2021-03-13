sun.install "sysstat"

sun.backup_move '/etc/default/sysstat'

systemctl enable sysstat
systemctl start sysstat
