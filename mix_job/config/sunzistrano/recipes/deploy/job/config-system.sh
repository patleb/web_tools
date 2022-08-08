if [[ "${passenger}" == true ]]; then
  desc 'Create job actions directory'
  mkdir -p "$shared_path/$(sun.flatten_path tmp/jobs)/actions"

  desc 'Create job systemd service'
  sun.compile "/etc/systemd/system/${job_service}.service" 0644 root:root
  sudo systemctl enable ${job_service}
  sudo systemctl daemon-reload

  desc 'Restart job service'
  job.restart
  export JOB_RESTART=false
elif systemctl list-unit-files | grep enabled | grep -Fq ${job_service}; then
  desc 'Stop job service'
  job.stop

  desc 'Remove job systemd service'
  systemctl disable ${job_service}
  sudo rm -f "/etc/systemd/system/${job_service}.service"
  sudo systemctl daemon-reload
fi
