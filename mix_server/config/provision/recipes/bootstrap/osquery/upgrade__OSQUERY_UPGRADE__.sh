__OSQUERY_UPGRADE__=${__OSQUERY_UPGRADE__:-false}
if [[ "$__OSQUERY_UPGRADE__" != false ]]; then
  sudo osqueryctl stop

  sun.unlock "osquery"
  sun.update
  sun.upgrade "osquery"
  sun.lock "osquery"

  sun.upgrade_compare "/opt/osquery/share/osquery/osquery.example.conf"
  sun.upgrade_compare "/opt/osquery/share/osquery/packs/hardware-monitoring.conf"
  sun.upgrade_compare "/opt/osquery/share/osquery/packs/incident-response.conf"
  sun.upgrade_compare "/opt/osquery/share/osquery/packs/it-compliance.conf"
  sun.upgrade_compare "/opt/osquery/share/osquery/packs/osquery-monitoring.conf"
  sun.upgrade_compare "/opt/osquery/share/osquery/packs/ossec-rootkit.conf"
  sun.upgrade_compare "/opt/osquery/share/osquery/packs/vuln-management.conf"

  sudo osqueryctl start
fi
