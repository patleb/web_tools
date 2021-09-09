export OSQUERY_KEY=1484120AC4E9F8A1A577AEEE97A80C63C9D8B80B
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys $OSQUERY_KEY
add-apt-repository 'deb [arch=amd64] https://pkg.osquery.io/deb deb main'
sun.update

sun.install "osquery"

sun.backup_compare "/usr/share/osquery/osquery.example.conf"
sun.backup_compare "/usr/share/osquery/packs/hardware-monitoring.conf"
sun.backup_compare "/usr/share/osquery/packs/incident-response.conf"
sun.backup_compare "/usr/share/osquery/packs/it-compliance.conf"
sun.backup_compare "/usr/share/osquery/packs/osquery-monitoring.conf"
sun.backup_compare "/usr/share/osquery/packs/ossec-rootkit.conf"
sun.backup_compare "/usr/share/osquery/packs/vuln-management.conf"

systemctl enable osqueryd
osqueryctl stop
