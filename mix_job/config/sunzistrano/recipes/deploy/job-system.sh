export job_service="${stage}-job-${job_queue}"

if [[ "${passenger}" == true ]]; then
  desc 'Create job actions directory'
  mkdir -p "$current_path/tmp/jobs/actions"

  desc 'Create and start job systemd service'
  sun.compile "/etc/systemd/system/$job_service.service" 0644 root:root
  sudo systemctl enable $job_service
  sudo systemctl daemon-reload
  sudo systemctl restart $job_service
fi
