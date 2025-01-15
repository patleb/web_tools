# TODO https://github.com/chainguard-dev/osquery-defense-kit
# TODO https://github.com/osquery/osquery/pull/8510/files
# https://github.com/osquery/osquery/issues/8105#issuecomment-1687415133
curl -fsSL  https://pkg.osquery.io/deb/pubkey.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/osquery.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/osquery.gpg] https://pkg.osquery.io/deb deb main" | sudo tee /etc/apt/sources.list.d/osquery.list > /dev/null
sun.update

sun.install "osquery"
sun.lock "osquery"

sun.backup_compare "/opt/osquery/share/osquery/osquery.example.conf"
sun.backup_compare "/opt/osquery/share/osquery/packs/hardware-monitoring.conf"
sun.backup_compare "/opt/osquery/share/osquery/packs/incident-response.conf"
sun.backup_compare "/opt/osquery/share/osquery/packs/it-compliance.conf"
sun.backup_compare "/opt/osquery/share/osquery/packs/osquery-monitoring.conf"
sun.backup_compare "/opt/osquery/share/osquery/packs/ossec-rootkit.conf"
sun.backup_compare "/opt/osquery/share/osquery/packs/vuln-management.conf"

systemctl mask --now systemd-journald-audit.socket
systemctl enable osqueryd
osqueryctl stop
