JOB_RESTART=${JOB_RESTART:-true}

if [[ "${passenger}" == true && "$JOB_RESTART" == true ]]; then
  desc 'Restart job service'
  sun.job_restart
fi
