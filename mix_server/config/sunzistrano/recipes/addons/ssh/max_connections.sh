# https://en.wikibooks.org/wiki/OpenSSH/Cookbook/Load_Balancing
ssh_max_connections=${ssh_max_connections:-10}

<%= Sh.delete_lines! '/etc/ssh/sshd_config', 'MaxStartups' %>
echo "MaxStartups ${ssh_max_connections}:30:100" >> /etc/ssh/sshd_config

<%= Sh.delete_lines! '/etc/ssh/sshd_config', 'MaxSessions' %>
echo "MaxSessions ${ssh_max_connections}" >> /etc/ssh/sshd_config

systemctl reload ssh
