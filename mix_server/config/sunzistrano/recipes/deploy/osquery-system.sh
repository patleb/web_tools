desc 'Export osquery configuration files'
sun.copy '/etc/osquery/osquery.conf' 0644 root:root
sun.copy '/etc/osquery/osquery.flags' 0644 root:root
sun.compile '/etc/logrotate.d/osquery' 0644 root:root

desc 'Restart osquery service'
osquery.restart
