# TODO https://jkraemer.net/2015/09/fail2ban-with-devise-based-rails-apps
# TODO https://www.blackhillsinfosec.com/configure-distributed-fail2ban/
# https://www.jeffgeerling.com/blog/2018/getting-best-performance-out-amazon-efs
# TODO https://askubuntu.com/questions/54771/potential-ufw-and-fail2ban-conflicts

sun.install "fail2ban"
sun.backup_copy "/etc/logrotate.d/fail2ban" 0440 root:root

systemctl enable fail2ban
systemctl start fail2ban
