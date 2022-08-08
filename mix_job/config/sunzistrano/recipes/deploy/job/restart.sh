JOB_RESTART=${JOB_RESTART:-true}

if [[ "$JOB_RESTART" == true ]]; then
  desc 'Restart job service'
  job.restart
fi
