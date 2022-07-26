if [[ "${system}" == true ]]; then
  desc "Add /etc/logrotate.d/${env}-${app}"
  sun.compile "/etc/logrotate.d/${env}-${app}" 0644 root:root
fi
