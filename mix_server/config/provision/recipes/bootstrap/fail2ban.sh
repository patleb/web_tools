# TODO https://jkraemer.net/2015/09/fail2ban-with-devise-based-rails-apps
# TODO https://www.blackhillsinfosec.com/configure-distributed-fail2ban/
# https://www.jeffgeerling.com/blog/2018/getting-best-performance-out-amazon-efs
# TODO https://askubuntu.com/questions/54771/potential-ufw-and-fail2ban-conflicts

sun.install "fail2ban"
sun.backup_move "/etc/logrotate.d/fail2ban"

systemctl enable fail2ban
systemctl start fail2ban
