sun.install "sysstat"

sun.backup_compile '/etc/default/sysstat'

systemctl enable sysstat
systemctl start sysstat
