__OSQUERY_UPGRADE__=${__OSQUERY_UPGRADE__:-false}
if [[ "$__OSQUERY_UPGRADE__" != false ]]; then
  sudo osqueryctl stop

  sun.unlock "osquery"
  sun.update
  sudo apt-get install -y osquery
  sun.lock "osquery"

  sun.remove_defaults "/opt/osquery/share/osquery/osquery.example.conf"
  sun.remove_defaults "/opt/osquery/share/osquery/packs/hardware-monitoring.conf"
  sun.remove_defaults "/opt/osquery/share/osquery/packs/incident-response.conf"
  sun.remove_defaults "/opt/osquery/share/osquery/packs/it-compliance.conf"
  sun.remove_defaults "/opt/osquery/share/osquery/packs/osquery-monitoring.conf"
  sun.remove_defaults "/opt/osquery/share/osquery/packs/ossec-rootkit.conf"
  sun.remove_defaults "/opt/osquery/share/osquery/packs/vuln-management.conf"

  sun.backup_compare "/opt/osquery/share/osquery/osquery.example.conf"
  sun.backup_compare "/opt/osquery/share/osquery/packs/hardware-monitoring.conf"
  sun.backup_compare "/opt/osquery/share/osquery/packs/incident-response.conf"
  sun.backup_compare "/opt/osquery/share/osquery/packs/it-compliance.conf"
  sun.backup_compare "/opt/osquery/share/osquery/packs/osquery-monitoring.conf"
  sun.backup_compare "/opt/osquery/share/osquery/packs/ossec-rootkit.conf"
  sun.backup_compare "/opt/osquery/share/osquery/packs/vuln-management.conf"

  sudo osqueryctl start
fi
