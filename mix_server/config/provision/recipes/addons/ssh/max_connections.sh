# https://en.wikibooks.org/wiki/OpenSSH/Cookbook/Load_Balancing
__SSH_MAX_CONNECTIONS__=${__SSH_MAX_CONNECTIONS__:-10}

<%= Sh.delete_lines! '/etc/ssh/sshd_config', 'MaxStartups' %>
echo "MaxStartups $__SSH_MAX_CONNECTIONS__:30:100" >> /etc/ssh/sshd_config

<%= Sh.delete_lines! '/etc/ssh/sshd_config', 'MaxSessions' %>
echo "MaxSessions $__SSH_MAX_CONNECTIONS__" >> /etc/ssh/sshd_config

systemctl reload ssh
