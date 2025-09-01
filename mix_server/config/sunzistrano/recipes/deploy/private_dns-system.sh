desc 'Set private dns in /etc/hosts'
if [[ "${cloud_cluster}" == true ]]; then
  <%= Sh.delete_lines! '/etc/hosts', sun.server_host, sudo: true %>
  <%= Sh.append_host Host::MASTER, Cloud.master_ip, sun.server_host %>
else
  <%= Sh.append_host Host::SERVER, '127.0.0.1', sun.server_host %>
  <%= Sh.append_host Host::HOSTNAME, '127.0.0.1', '$(hostname)', if: "'#{sun.server_host}' != $(hostname)" %>
fi
