job.maintenance_enable() {
  if [[ "${passenger}" == true ]]; then
    job.stop
  fi
}
nginx_maintenance_enable_before+=('job.maintenance_enable')

job.maintenance_disable() {
  if [[ "${passenger}" == true ]]; then
    job.start
  fi
}
nginx_maintenance_disable_after+=('job.maintenance_disable')

job.start() { # PUBLIC
  sudo systemctl start "${job_service}"
}

job.stop() { # PUBLIC
  sudo systemctl stop "${job_service}"
}

job.restart() { # PUBLIC
  sudo systemctl restart "${job_service}"
}

job.wait_enable() { # PUBLIC
  touch "$shared_path/$(sun.flatten_path tmp/jobs)/wait.txt"
}

job.wait_disable() { # PUBLIC
  rm -f "$shared_path/$(sun.flatten_path tmp/jobs)/wait.txt"
}
