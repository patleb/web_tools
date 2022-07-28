sun.job_start() {
  sudo systemctl start "${job_service}"
}

sun.job_stop() {
  sudo systemctl stop "${job_service}"
}

sun.job_restart() {
  sudo systemctl restart "${job_service}"
}

sun.job_wait_enable() {
  touch "$shared_path/$(sun.flatten_path tmp/jobs)/wait.txt"
}

sun.job_wait_disable() {
  rm -f "$shared_path/$(sun.flatten_path tmp/jobs)/wait.txt"
}
