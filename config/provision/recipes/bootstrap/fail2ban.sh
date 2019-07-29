# TODO https://jkraemer.net/2015/09/fail2ban-with-devise-based-rails-apps
# TODO https://www.blackhillsinfosec.com/configure-distributed-fail2ban/
# https://www.jeffgeerling.com/blog/2018/getting-best-performance-out-amazon-efs
# TODO https://askubuntu.com/questions/54771/potential-ufw-and-fail2ban-conflicts

sun.install "fail2ban"

case "$OS" in
ubuntu)
  # TODO
;;
centos)
  if systemctl list-unit-files | grep enabled | grep -Fq firewalld; then
    systemctl disable firewalld
  fi
  sun.install "fail2ban-systemd"
  sun.move "/etc/fail2ban/action.d/ufw_ssh.conf"
  sun.backup_move "/etc/fail2ban/jail.conf"
;;
esac

systemctl enable fail2ban
systemctl start fail2ban
